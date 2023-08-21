// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import "../eip712/EIP712Verifier.sol";
import "../interface/IAttestation.sol";
import "./Schema.sol";
import "./Module.sol";

import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";

// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

import {
    AccessDenied, NotFound, NO_EXPIRATION_TIME, InvalidLength, uncheckedInc
} from "../Common.sol";

import "forge-std/console2.sol";

struct AttestationsResult {
    uint256 usedValue; // Total ETH amount that was sent to resolvers.
    bytes32[] uids; // UIDs of the new attestations.
}
/**
 * @title Module
 *
 * @author zeroknots
 */

abstract contract Attestation is IAttestation, EIP712Verifier {
    using Address for address payable;
    using ModuleDeploymentLib for address;

    mapping(address module => mapping(address authority => AttestationRecord attestation)) internal
        _moduleToAuthorityToAttestations;

    // mapping(bytes32 uid => AttestationRecord attestation) internal _attestations;
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
    error InvalidAttestationRefUID(bytes32 missingRefUID);
    error IncompatibleAttestation(bytes32 sourceCodeHash, bytes32 targetCodeHash);
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
        address _l1Registry,
        string memory name,
        string memory version
    )
        EIP712Verifier(name, version)
    {
        yaho = _yaho;
        yaru = _yaru;
        l1Registry = _l1Registry;
    }

    /**
     * @inheritdoc IAttestation
     */
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

    /**
     * @inheritdoc IAttestation
     */
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable
        returns (bytes32[] memory attestationIds)
    {
        uint256 length = multiDelegatedRequests.length;

        // Since a multi-attest call is going to make multiple attestations for multiple schemas, we'd need to collect
        // all the returned UIDs into a single list.
        bytes32[][] memory totalUids = new bytes32[][](length);
        uint256 totalUidsCount;

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
            uint256 dataLength = data.length;

            // Ensure that no inputs are missing.
            if (dataLength == 0 || dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; j = uncheckedInc(j)) {
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

    /**
     * @inheritdoc IAttestation
     */
    function propagateAttest(
        address to,
        uint256 toChainId,
        bytes32[] memory attestationIds,
        address moduleOnL2
    )
        external
        returns (Message[] memory messages, bytes32[] memory messageIds)
    {
        uint256 length = attestationIds.length;
        messages = new Message[](length);
        messageIds = new bytes32[](length);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            AttestationRecord memory attestationRecord = _getAttestation(attestationIds[i]);
            _resolvePropagation(attestationRecord, to, toChainId, moduleOnL2);
            if (attestationRecord.uid == EMPTY_UID) {
                revert InvalidAttestation();
            }
            // Encode the attestation record into a data payload.
            bytes memory callData = abi.encodeWithSelector(
                this.attestByPropagation.selector,
                attestationRecord,
                attestationRecord.subject.codeHash(),
                moduleOnL2
            );
            // Prepare the message for dispatch.
            messages[i] = Message({ to: to, toChainId: toChainId, data: callData });
        }
        messageIds = yaho.dispatchMessages(messages);
    }
    /**
     * @inheritdoc IAttestation
     */

    function propagateAttest(
        address to,
        uint256 toChainId,
        bytes32 attestationId,
        address moduleOnL2
    )
        public
        returns (Message[] memory messages, bytes32[] memory messageIds)
    {
        // Get the attestation record for the contract and the authority.
        AttestationRecord memory attestationRecord = _getAttestation(attestationId);
        bytes32 codeHash = attestationRecord.subject.codeHash();

        _resolvePropagation(attestationRecord, to, toChainId, moduleOnL2);

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

    /**
     * @inheritdoc IAttestation
     */
    function attestByPropagation(
        AttestationRecord calldata attestation,
        bytes32 codeHash,
        address moduleAddress
    )
        external
        onlyHashi
    {
        // Check if the code hash from sending chain matches the hash of the module address
        // if codeHash does not match, the attestation is invalid
        if (codeHash != moduleAddress.codeHash()) {
            revert IncompatibleAttestation(codeHash, moduleAddress.codeHash());
        }

        // check if schemaId exists on this L2 registry
        if (getSchema(attestation.schema).uid == EMPTY_UID) revert WrongSchema();

        // check if refUID exists on this L2 registry
        if (attestation.refUID != EMPTY_UID) {
            // check if refUID exists on this L2 registry
            if (_getAttestation(attestation.refUID).uid == EMPTY_UID) {
                revert InvalidAttestationRefUID(attestation.refUID);
            }
        }

        // check if attestationId already exists on this L2 registry
        AttestationRecord storage existingRecord = _getAttestation(attestation.uid);
        if (existingRecord.revocationTime != 0) revert InvalidAttestation();
        // can not propagate attestations that were commited natively after the original attestation was created
        if (existingRecord.time > attestation.time) revert InvalidAttestation();

        // Store the attestation
        _moduleToAuthorityToAttestations[attestation.subject][attestation.attester] = attestation;
        // Emit an event for the attestation
        emit Attested(
            attestation.subject, attestation.attester, attestation.uid, attestation.schema
        );
    }

    /**
     * @inheritdoc IAttestation
     */
    function revoke(DelegatedRevocationRequest calldata request) external payable {
        _verifyRevoke(request);

        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = request.data;

        _revoke(request.schema, data, request.revoker, msg.value, true);
    }

    /**
     * @inheritdoc IAttestation
     */
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

    /**
     * @dev Attests to a specific schema.
     *
     * @param schema // the unique identifier of the schema to attest to.
     * @param data The arguments of the attestation requests.
     * @param attester The attesting account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return res The AttestationResult struct
     */
    function _attest(
        bytes32 schema,
        AttestationRequestData[] memory data,
        address attester,
        uint256 availableValue,
        bool last
    )
        private
        returns (AttestationsResult memory res)
    {
        uint256 length = data.length;

        res.uids = new bytes32[](length);

        // Ensure that we aren't attempting to attest to a non-existing schema.
        SchemaRecord memory schemaRecord = getSchema(schema);
        if (schemaRecord.uid == EMPTY_UID) {
            revert InvalidSchema();
        }

        AttestationRecord[] memory attestations = new AttestationRecord[](length);
        uint256[] memory values = new uint256[](length);

        // caching the current time
        uint48 timeNow = _time();

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            AttestationRequestData memory request = data[i];

            // Ensure that either no expiration time was set or that it was set in the future.
            if (request.expirationTime != NO_EXPIRATION_TIME && request.expirationTime <= timeNow) {
                revert InvalidExpirationTime();
            }

            // Ensure that we aren't trying to make a revocable attestation for a non-revocable schema.
            if (!schemaRecord.revocable && request.revocable) {
                revert Irrevocable();
            }

            // Ensure that attestation is for module that was registered.
            if (_getModule(request.subject).implementation == address(0)) {
                revert InvalidAttestation();
            }

            // Ensure that attestation for a module is using the modules schemaId
            if (_getModule(request.subject).schemaId != schema) {
                revert InvalidAttestation();
            }

            AttestationRecord memory attestation = AttestationRecord({
                uid: EMPTY_UID,
                schema: schema,
                refUID: request.refUID,
                time: timeNow,
                expirationTime: request.expirationTime,
                revocationTime: 0,
                subject: request.subject,
                attester: attester,
                revocable: request.revocable,
                propagateable: request.propagateable,
                data: request.data
            });

            // Look for the first non-existing UID (and use a bump seed/nonce in the rare case of a conflict).
            bytes32 uid = _getAttestationID(request.subject, attester);
            attestation.uid = uid;

            // saving into contract storage
            _moduleToAuthorityToAttestations[request.subject][attester] = attestation;

            if (request.refUID != 0) {
                // Ensure that we aren't trying to attest to a non-existing referenced UID.
                if (!isAttestationValid(request.refUID)) {
                    revert NotFound();
                }
            }

            attestations[i] = attestation;
            values[i] = request.value;

            res.uids[i] = uid;

            emit Attested(request.subject, attester, uid, schema);
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
        AttestationRecord[] memory attestations = new AttestationRecord[](length);
        uint256[] memory values = new uint256[](length);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            RevocationRequestData memory request = data[i];

            AttestationRecord storage attestation = _getAttestation(request.uid);

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

            // Please note tModuleRecordhat also checking of the schema itself is revocable is unnecessary, since it's not possible to
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

            emit Revoked(attestation.subject, revoker, request.uid, attestation.schema);
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
        AttestationRecord memory attestation,
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
        AttestationRecord[] memory attestations,
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

    function _newUID(AttestationRecord memory attestation) private view returns (bytes32 uid) {
        uint256 bump;
        while (true) {
            uid = _getUID(attestation, bump);
            if (_getAttestation(uid).uid == EMPTY_UID) {
                return uid;
            }

            unchecked {
                ++bump;
            }
        }
    }

    /**
     * @inheritdoc IAttestation
     */
    function predictAttestationUID(
        bytes32 schema,
        address attester,
        AttestationRequestData memory request
    )
        external
        view
        returns (bytes32 uid)
    {
        AttestationRecord memory attestation = AttestationRecord({
            uid: EMPTY_UID,
            schema: schema,
            refUID: request.refUID,
            time: _time(),
            expirationTime: request.expirationTime,
            revocationTime: 0,
            subject: request.subject,
            attester: attester,
            revocable: request.revocable,
            propagateable: request.propagateable,
            data: request.data
        });
        return _newUID(attestation);
    }

    /**
     * @dev Calculates a UID for a given attestation.
     *
     * @param attestation The input attestation.
     * @param bump A bump value to use in case of a UID conflict.
     *
     * @return Attestation UID.
     */
    function _getUID(
        AttestationRecord memory attestation,
        uint256 bump
    )
        private
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                attestation.schema,
                attestation.subject,
                attestation.attester,
                // attestation.time, <-- makes UIDs unpredictable. is removing this a security issue?
                attestation.expirationTime,
                attestation.revocable,
                attestation.refUID,
                attestation.data,
                bump
            )
        );
    }

    /**
     * @notice Converts an array of bytes32 to an array of uint256
     *
     * @dev Iterates over the input array and converts each bytes32 to uint256
     *
     * @param array The array of bytes32 to convert
     *
     * @return array2 The converted array of uint256
     */
    function _toUint256Array(bytes32[] memory array) internal pure returns (uint256[] memory) {
        uint256 length = array.length;
        uint256[] memory array2 = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            array2[i] = uint256(array[i]);
        }
        return array2;
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
        uint256 uidListsLength = uidLists.length;
        for (uint256 i; i < uidListsLength; i = uncheckedInc(i)) {
            bytes32[] memory currentUids = uidLists[i];
            uint256 currentUidsLength = currentUids.length;
            for (uint256 j; j < currentUidsLength; j = uncheckedInc(j)) {
                uids[currentIndex] = currentUids[j];

                unchecked {
                    ++currentIndex;
                }
            }
        }

        return uids;
    }

    function isAttestationValid(bytes32 uid) public view returns (bool) {
        return _getAttestation(uid).uid != 0;
    }

    // Modifier that checks the validity of the caller and sender.
    modifier onlyHashi() {
        if (yaru.sender() != l1Registry) revert InvalidSender(address(this), yaru.sender());
        if (msg.sender != address(yaru)) revert InvalidCaller(address(this), msg.sender);
        _;
    }

    function _resolvePropagation(
        AttestationRecord memory attestation,
        address to,
        uint256 toChainId,
        address moduleOnL2
    )
        private
        returns (bool)
    {
        ISchemaResolver resolver = getSchema(attestation.schema).resolver;
        if (address(resolver) != address(0)) {
            bool valid = resolver.propagation(attestation, msg.sender, to, toChainId, moduleOnL2);
            if (valid) return valid;
            else revert InvalidPropagation();
        }
    }

    function _enforceOnlySchemaOwner(bytes32 schema) internal view {
        address schemaOwner = getSchema(schema).schemaOwner;
        if (schemaOwner != msg.sender) {
            revert AccessDenied();
        }
    }

    function getSchema(bytes32 uid) public view virtual returns (SchemaRecord memory);

    function getBridges(bytes32 uid) public view virtual returns (address[] memory);

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        returns (ModuleRecord storage);

    function _getAttestation(
        address module,
        address authority
    )
        internal
        view
        virtual
        returns (AttestationRecord storage)
    {
        return _moduleToAuthorityToAttestations[module][authority];
    }

    /*//////////////////////////////////////////////////////////////
                              Attestation ID 
    //////////////////////////////////////////////////////////////*/

    function _getAttestationID(
        address module,
        address attester
    )
        internal
        view
        returns (bytes32 id)
    {
        AttestationRecord storage attestation = _getAttestation(module, attester);
        assembly {
            id := attestation.slot
        }
    }

    function _getAttestation(bytes32 id)
        internal
        pure
        returns (AttestationRecord storage attestation)
    {
        assembly {
            attestation.slot := id
        }
    }
}
