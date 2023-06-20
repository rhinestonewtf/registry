// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import "./eip712/EIP712Verifier.sol";
import "./IRSAttestation.sol";
import "./RSSchema.sol";
import "./RSModuleRegistry.sol";

import { RSRegistryLib } from "./lib/RSRegistryLib.sol";

// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

import {
    AccessDenied, NotFound, NO_EXPIRATION_TIME, InvalidLength, uncheckedInc
} from "./Common.sol";

struct AttestationsResult {
    uint256 usedValue; // Total ETH amount that was sent to resolvers.
    bytes32[] uids; // UIDs of the new attestations.
}
/// @title RSAttestation
/// @author zeroknots
/// @notice ContractDescription

contract RSAttestation is IRSAttestation, RSModuleRegistry, EIP712Verifier {
    using Address for address payable;
    using RSRegistryLib for address;

    mapping(bytes32 uid => Attestation attestation) internal _attestations;
    mapping(address module => mapping(address authority => bytes32 attestationId)) internal
        _moduleToAuthorityToAttestations;

    // Instance of Hashi's Yaho contract.
    Yaho public yaho;
    // Instance of Hashi's Yaru contract.
    Yaru public yaru;

    // address of L1 registry
    address public l1Registry;

    error AlreadyRevoked();
    error AlreadyRevokedOffchain();
    error AlreadyTimestamped();
    error InsufficientValue();
    error InvalidAttestation();
    error InvalidPropagation();
    error InvalidAttestations();
    error InvalidExpirationTime();
    error InvalidOffset();
    error InvalidRegistry();
    error InvalidRevocation();
    error InvalidRevocations();
    error InvalidVerifier();
    error Irrevocable();
    error NotPayable();
    error WrongSchema();
    error InvalidSender(address moduleAddr, address sender); // Emitted when the sender address is invalid.
    error InvalidCaller(address moduleAddr, address yaruSender); // Emitted when the caller is not the Yaru contract.

    constructor(
        Yaho _yaho,
        Yaru _yaru,
        address _l1Registry
    )
        EIP712Verifier("RSAttestaton", "1.0")
    {
        yaho = _yaho;
        yaru = _yaru;
        l1Registry = _l1Registry;
    }

    function attest(DelegatedAttestationRequest calldata delegatedRequest)
        external
        payable
        returns (bytes32 attestationId)
    {
        _verifyAttest(delegatedRequest);

        AttestationRequestData[] memory data = new AttestationRequestData[](1);
        data[0] = delegatedRequest.data;

        return _attest(delegatedRequest.schema, data, delegatedRequest.attester, msg.value, true)
            .uids[0];
    }

    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable
        returns (bytes32[] memory attestationIds)
    {
        uint256 length = multiDelegatedRequests.length;

        // Since a multi-attest call is going to make multiple attestations for multiple schemas, we'd need to collect
        // all the returned UIDs into a single list.
        bytes32[][] memory totalUids = new bytes32[][](length);
        uint256 totalUidsCount = 0;

        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedAttestationRequest calldata multiDelegatedRequest =
                multiDelegatedRequests[i];
            AttestationRequestData[] calldata data = multiDelegatedRequest.data;

            // Ensure that no inputs are missing.
            if (data.length == 0 || data.length != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j = 0; j < data.length; j = uncheckedInc(j)) {
                _verifyAttest(
                    DelegatedAttestationRequest({
                        schema: multiDelegatedRequest.schema,
                        data: data[j],
                        signature: multiDelegatedRequest.signatures[j],
                        attester: multiDelegatedRequest.attester
                    })
                );
            }

            // Process the current batch of attestations.
            AttestationsResult memory res = _attest(
                multiDelegatedRequest.schema,
                data,
                multiDelegatedRequest.attester,
                availableValue,
                last
            );

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= res.usedValue;

            // Collect UIDs (and merge them later).
            totalUids[i] = res.uids;
            unchecked {
                totalUidsCount += res.uids.length;
            }
        }

        // Merge all the collected UIDs and return them as a flatten array.
        return _mergeUIDs(totalUids, totalUidsCount);
    }

    function propagateAttest(
        address to,
        uint256 toChainId,
        bytes32 attestationId,
        address moduleOnL2
    )
        external
        returns (Message[] memory messages, bytes32[] memory messageIds)
    {
        // Get the attestation record for the contract and the authority.
        Attestation memory attestationRecord = _attestations[attestationId];
        Module memory module = _modules[attestationRecord.recipient];
        bytes32 codeHash = module.implementation.codeHash();

        if (attestationRecord.propagateable == false) {
            revert InvalidAttestation();
        }

        // Encode the attestation record into a data payload.
        bytes memory callReceiveFnOnL2 = abi.encodeWithSelector(
            this.attestByPropagation.selector, attestationRecord, codeHash, moduleOnL2
        );

        // Prepare the message for dispatch.
        messages = new Message[](1);
        messages[0] = Message({ to: to, toChainId: toChainId, data: callReceiveFnOnL2 });

        messageIds = new bytes32[](1);
        // Dispatch message to selected L2
        messageIds = yaho.dispatchMessages(messages);
    }

    function attestByPropagation(
        Attestation calldata attestation,
        bytes32 codeHash,
        address moduleAddress
    )
        external
        onlyHashi
    {
        if (codeHash != moduleAddress.codeHash()) {
            revert InvalidAttestation();
        }

        _attestations[attestation.uid] = attestation;
        emit Attested(
            attestation.recipient, attestation.attester, attestation.uid, attestation.schema
        );
    }

    function revoke(DelegatedRevocationRequest calldata request) external payable {
        _verifyRevoke(request);

        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = request.data;

        _revoke(request.schema, data, request.revoker, msg.value, true);
    }

    function multiRevoke(MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests)
        external
        payable
    {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;
        uint256 length = multiDelegatedRequests.length;

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedRevocationRequest memory multiDelegatedRequest = multiDelegatedRequests[i];
            RevocationRequestData[] memory data = multiDelegatedRequest.data;
            uint256 dataLength = data.length;

            // Ensure that no inputs are missing.
            if (dataLength == 0 || dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; j = uncheckedInc(j)) {
                _verifyRevoke(
                    DelegatedRevocationRequest({
                        schema: multiDelegatedRequest.schema,
                        data: data[j],
                        signature: multiDelegatedRequest.signatures[j],
                        revoker: multiDelegatedRequest.revoker
                    })
                );
            }

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _revoke(
                multiDelegatedRequest.schema,
                data,
                multiDelegatedRequest.revoker,
                availableValue,
                last
            );
        }
    }

    function getAttestationDigest(
        AttestationRequestData memory attData,
        bytes32 schemaUid,
        address attester
    )
        public
        view
        returns (bytes32 digest)
    {
        bytes32 ATTEST_TYPEHASH = getAttestTypeHash();
        uint256 nonce = getNonce(attester);
        bytes32 structHash = keccak256(
            abi.encode(
                ATTEST_TYPEHASH,
                schemaUid,
                attData.recipient,
                attData.expirationTime,
                attData.revocable,
                attData.refUID,
                keccak256(attData.data),
                nonce
            )
        );
        digest = ECDSA.toTypedDataHash(getDomainSeparator(), structHash);
    }

    /**
     * @dev Attests to a specific schema.
     *
     * @param schema // the unique identifier of the schema to attest to.
     * @param data The arguments of the attestation requests.
     * @param attester The attesting account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return The UID of the new attestations and the total sent ETH amount.
     */
    function _attest(
        bytes32 schema,
        AttestationRequestData[] memory data,
        address attester,
        uint256 availableValue,
        bool last
    )
        private
        returns (AttestationsResult memory)
    {
        uint256 length = data.length;

        AttestationsResult memory res;
        res.uids = new bytes32[](length);

        // Ensure that we aren't attempting to attest to a non-existing schema.
        SchemaRecord memory schemaRecord = getSchema(schema);
        if (schemaRecord.uid == EMPTY_UID) {
            revert InvalidSchema();
        }

        Attestation[] memory attestations = new Attestation[](length);
        uint256[] memory values = new uint256[](length);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            AttestationRequestData memory request = data[i];

            // Ensure that either no expiration time was set or that it was set in the future.
            if (request.expirationTime != NO_EXPIRATION_TIME && request.expirationTime <= _time()) {
                revert InvalidExpirationTime();
            }

            // Ensure that we aren't trying to make a revocable attestation for a non-revocable schema.
            if (!schemaRecord.revocable && request.revocable) {
                revert Irrevocable();
            }

            // Ensure that attestation is for module that was registered.
            if (_modules[request.recipient].implementation == address(0)) {
                revert InvalidAttestation();
            }

            Attestation memory attestation = Attestation({
                uid: EMPTY_UID,
                schema: schema,
                refUID: request.refUID,
                time: _time(),
                expirationTime: request.expirationTime,
                revocationTime: 0,
                recipient: request.recipient,
                attester: attester,
                revocable: request.revocable,
                propagateable: request.propagateable,
                data: request.data
            });

            // Look for the first non-existing UID (and use a bump seed/nonce in the rare case of a conflict).
            bytes32 uid;

            // creating scope to avoid stack too deep
            {
                uint32 bump;
                while (true) {
                    uid = _getUID(attestation, bump);
                    if (_attestations[uid].uid == EMPTY_UID) {
                        break;
                    }

                    unchecked {
                        ++bump;
                    }
                }
            }
            attestation.uid = uid;

            // saving into contract storage
            _attestations[uid] = attestation;
            _moduleToAuthorityToAttestations[request.recipient][attester] = uid;

            if (request.refUID != 0) {
                // Ensure that we aren't trying to attest to a non-existing referenced UID.
                if (!isAttestationValid(request.refUID)) {
                    revert NotFound();
                }
            }

            attestations[i] = attestation;
            values[i] = request.value;

            res.uids[i] = uid;

            emit Attested(request.recipient, attester, uid, schema);
        }

        res.usedValue =
            _resolveAttestations(schemaRecord, attestations, values, false, availableValue, last);

        return res;
    }

    /**
     * @dev Revokes an existing attestation to a specific schema.
     *
     * @param schema The unique identifier of the schema to attest to.
     * @param data The arguments of the revocation requests.
     * @param revoker The revoking account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _revoke(
        bytes32 schema,
        RevocationRequestData[] memory data,
        address revoker,
        uint256 availableValue,
        bool last
    )
        private
        returns (uint256)
    {
        // Ensure that a non-existing schema ID wasn't passed by accident.
        SchemaRecord memory schemaRecord = getSchema(schema);
        if (schemaRecord.uid == EMPTY_UID) {
            revert InvalidSchema();
        }

        uint256 length = data.length;
        Attestation[] memory attestations = new Attestation[](length);
        uint256[] memory values = new uint256[](length);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            RevocationRequestData memory request = data[i];

            Attestation storage attestation = _attestations[request.uid];

            // Ensure that we aren't attempting to revoke a non-existing attestation.
            if (attestation.uid == EMPTY_UID) {
                revert NotFound();
            }

            // Ensure that a wrong schema ID wasn't passed by accident.
            if (attestation.schema != schema) {
                revert InvalidSchema();
            }

            // Allow only original attesters to revoke their attestations.
            if (attestation.attester != revoker) {
                revert AccessDenied();
            }

            // Please note that also checking of the schema itself is revocable is unnecessary, since it's not possible to
            // make revocable attestations to an irrevocable schema.
            if (!attestation.revocable) {
                revert Irrevocable();
            }

            // Ensure that we aren't trying to revoke the same attestation twice.
            if (attestation.revocationTime != 0) {
                revert AlreadyRevoked();
            }
            attestation.revocationTime = _time();

            attestations[i] = attestation;
            values[i] = request.value;

            emit Revoked(attestation.recipient, revoker, request.uid, attestation.schema);
        }

        return _resolveAttestations(schemaRecord, attestations, values, true, availableValue, last);
    }

    /**
     * @dev Resolves a new attestation or a revocation of an existing attestation.
     *
     * @param schemaRecord The schema of the attestation.
     * @param attestation The data of the attestation to make/revoke.
     * @param value An explicit ETH amount to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _resolveAttestation(
        SchemaRecord memory schemaRecord,
        Attestation memory attestation,
        uint256 value,
        bool isRevocation,
        uint256 availableValue,
        bool last
    )
        private
        returns (uint256)
    {
        ISchemaResolver resolver = schemaRecord.resolver;
        if (address(resolver) == address(0)) {
            // Ensure that we don't accept payments if there is no resolver.
            if (value != 0) {
                revert NotPayable();
            }

            return 0;
        }

        // Ensure that we don't accept payments which can't be forwarded to the resolver.
        if (value != 0 && !resolver.isPayable()) {
            revert NotPayable();
        }

        // Ensure that the attester/revoker doesn't try to spend more than available.
        if (value > availableValue) {
            revert InsufficientValue();
        }

        // Ensure to deduct the sent value explicitly.
        unchecked {
            availableValue -= value;
        }

        if (isRevocation) {
            if (!resolver.revoke{ value: value }(attestation)) {
                revert InvalidRevocation();
            }
        } else if (!resolver.attest{ value: value }(attestation)) {
            revert InvalidAttestation();
        }

        if (last) {
            _refund(availableValue);
        }

        return value;
    }

    /**
     * @dev Resolves multiple attestations or revocations of existing attestations.
     *
     * @param schemaRecord The schema of the attestation.
     * @param attestations The data of the attestations to make/revoke.
     * @param values Explicit ETH amounts to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _resolveAttestations(
        SchemaRecord memory schemaRecord,
        Attestation[] memory attestations,
        uint256[] memory values,
        bool isRevocation,
        uint256 availableValue,
        bool last
    )
        private
        returns (uint256)
    {
        uint256 length = attestations.length;
        if (length == 1) {
            return _resolveAttestation(
                schemaRecord, attestations[0], values[0], isRevocation, availableValue, last
            );
        }

        ISchemaResolver resolver = schemaRecord.resolver;
        if (address(resolver) == address(0)) {
            // Ensure that we don't accept payments if there is no resolver.
            for (uint256 i; i < length; i = uncheckedInc(i)) {
                if (values[i] != 0) {
                    revert NotPayable();
                }
            }

            return 0;
        }

        uint256 totalUsedValue;

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            uint256 value = values[i];

            // Ensure that we don't accept payments which can't be forwarded to the resolver.
            if (value != 0 && !resolver.isPayable()) {
                revert NotPayable();
            }

            // Ensure that the attester/revoker doesn't try to spend more than available.
            if (value > availableValue) {
                revert InsufficientValue();
            }

            // Ensure to deduct the sent value explicitly and add it to the total used value by the batch.
            unchecked {
                availableValue -= value;
                totalUsedValue += value;
            }
        }

        if (isRevocation) {
            if (!resolver.multiRevoke{ value: totalUsedValue }(attestations, values)) {
                revert InvalidRevocations();
            }
        } else if (!resolver.multiAttest{ value: totalUsedValue }(attestations, values)) {
            revert InvalidAttestations();
        }

        if (last) {
            _refund(availableValue);
        }

        return totalUsedValue;
    }

    /**
     * @dev Calculates a UID for a given attestation.
     *
     * @param attestation The input attestation.
     * @param bump A bump value to use in case of a UID conflict.
     *
     * @return Attestation UID.
     */
    function _getUID(Attestation memory attestation, uint32 bump) private pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                attestation.schema,
                attestation.recipient,
                attestation.attester,
                attestation.time,
                attestation.expirationTime,
                attestation.revocable,
                attestation.refUID,
                attestation.data,
                bump
            )
        );
    }

    /**
     * @dev Refunds remaining ETH amount to the attester.
     *
     * @param remainingValue The remaining ETH amount that was not sent to the resolver.
     */
    function _refund(uint256 remainingValue) private {
        if (remainingValue > 0) {
            // Using a regular transfer here might revert, for some non-EOA attesters, due to exceeding of the 2300
            // gas limit which is why we're using call instead (via sendValue), which the 2300 gas limit does not
            // apply for.
            payable(msg.sender).sendValue(remainingValue);
        }
    }

    /**
     * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
     * current block time.
     */
    function _time() internal view virtual returns (uint48) {
        return uint48(block.timestamp);
    }

    /**
     * @dev Merges lists of UIDs.
     *
     * @param uidLists The provided lists of UIDs.
     * @param uidsCount Total UIDs count.
     *
     * @return A merged and flatten list of all the UIDs.
     */
    function _mergeUIDs(
        bytes32[][] memory uidLists,
        uint256 uidsCount
    )
        private
        pure
        returns (bytes32[] memory)
    {
        bytes32[] memory uids = new bytes32[](uidsCount);

        uint256 currentIndex = 0;
        for (uint256 i = 0; i < uidLists.length; i = uncheckedInc(i)) {
            bytes32[] memory currentUids = uidLists[i];
            for (uint256 j = 0; j < currentUids.length; j = uncheckedInc(j)) {
                uids[currentIndex] = currentUids[j];

                unchecked {
                    ++currentIndex;
                }
            }
        }

        return uids;
    }

    function isAttestationValid(bytes32 uid) public view returns (bool) {
        return _attestations[uid].uid != 0;
    }

    // Modifier that checks the validity of the caller and sender.
    modifier onlyHashi() {
        if (yaru.sender() != l1Registry) revert InvalidSender(address(this), yaru.sender());
        if (msg.sender != address(yaru)) revert InvalidCaller(address(this), msg.sender);
        _;
    }
}
