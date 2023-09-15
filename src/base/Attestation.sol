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
    AccessDenied,
    NotFound,
    NO_EXPIRATION_TIME,
    InvalidLength,
    uncheckedInc,
    InvalidSchema,
    _time
} from "../Common.sol";

import "forge-std/console2.sol";

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
    error NotPayable();
    error WrongSchema();
    error InvalidSender(address moduleAddr, address sender); // Emitted when the sender address is invalid.
    error InvalidCaller(address moduleAddr, address yaruSender); // Emitted when the caller is not the Yaru contract.

    constructor(string memory name, string memory version) EIP712Verifier(name, version) { }

    function attest(AttestationRequest calldata request) external payable {
        AttestationRequestData[] memory requests = new AttestationRequestData[](
            1
        );
        requests[0] = request.data;

        ModuleRecord storage moduleRecord = _getModule(request.data.subject);

        _attest(request.schemaUID, moduleRecord.resolverUID, requests, msg.sender, msg.value, true);
    }

    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable {
        uint256 length = multiRequests.length;
        uint256 availableValue = msg.value;

        ModuleRecord storage moduleRecord = _getModule(multiRequests[0].data[0].subject);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            bool last;
            unchecked {
                last = i == length - 1;
            }

            // Process the current batch of attestations.
            MultiAttestationRequest calldata multiRequest = multiRequests[i];
            uint256 usedValue = _attest(
                multiRequest.schemaUID,
                moduleRecord.resolverUID,
                multiRequest.data,
                msg.sender,
                availableValue,
                last
            );

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= usedValue;
        }
    }

    /**
     * @inheritdoc IAttestation
     */
    function attest(DelegatedAttestationRequest calldata delegatedRequest) external payable {
        _verifyAttest(delegatedRequest);

        AttestationRequestData[] memory data = new AttestationRequestData[](1);
        data[0] = delegatedRequest.data;

        ModuleRecord memory moduleRecord = _getModule(delegatedRequest.data.subject);

        _attest(
            delegatedRequest.schemaUID,
            moduleRecord.resolverUID,
            data,
            delegatedRequest.attester,
            msg.value,
            true
        );
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable
    {
        uint256 length = multiDelegatedRequests.length;

        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        // this breaks the functionality to multiAttest on different modules right?
        ModuleRecord memory moduleRecord = _getModule(multiDelegatedRequests[0].data[0].subject);
        // I think it would be much better to move this into the for loop so we can iterate over the requests.
        // Its possible that the MultiAttestationRequests is attesting different modules, that thus have different resolvers
        // gas bad

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
                        schemaUID: multiDelegatedRequest.schemaUID,
                        data: data[j],
                        signature: multiDelegatedRequest.signatures[j],
                        attester: multiDelegatedRequest.attester
                    })
                );
            }

            // Process the current batch of attestations.
            uint256 usedValue = _attest(
                multiDelegatedRequest.schemaUID,
                moduleRecord.resolverUID,
                data,
                multiDelegatedRequest.attester,
                availableValue,
                last
            );

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= usedValue;
        }
    }

    function revoke(RevocationRequest calldata request) external payable {
        RevocationRequestData[] memory requests = new RevocationRequestData[](
            1
        );
        requests[0] = request.data;

        ModuleRecord memory moduleRecord = _getModule(request.data.subject);

        _revoke(request.schemaUID, moduleRecord.resolverUID, requests, msg.sender, msg.value, true);
    }

    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        ModuleRecord memory moduleRecord = _getModule(multiRequests[0].data[0].subject);

        // should cache length
        for (uint256 i = 0; i < multiRequests.length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == multiRequests.length - 1;
            }

            MultiRevocationRequest calldata multiRequest = multiRequests[i];

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _revoke(
                multiRequest.schemaUID,
                moduleRecord.resolverUID,
                multiRequest.data,
                msg.sender,
                availableValue,
                last
            );
        }
    }

    /**
     * @inheritdoc IAttestation
     */
    function revoke(DelegatedRevocationRequest calldata request) external payable {
        _verifyRevoke(request);

        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = request.data;

        ModuleRecord memory moduleRecord = _getModule(request.data.subject);

        _revoke(request.schemaUID, moduleRecord.resolverUID, data, request.revoker, msg.value, true);
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

        ModuleRecord memory moduleRecord = _getModule(multiDelegatedRequests[0].data[0].subject);

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
                        schemaUID: multiDelegatedRequest.schemaUID,
                        data: data[j],
                        signature: multiDelegatedRequest.signatures[j],
                        revoker: multiDelegatedRequest.revoker
                    })
                );
            }

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _revoke(
                multiDelegatedRequest.schemaUID,
                moduleRecord.resolverUID,
                data,
                multiDelegatedRequest.revoker,
                availableValue,
                last
            );
        }
    }

    function _enforceExistingSchema(SchemaUID schemaUID) private view {
        // TODO make this storage
        SchemaRecord storage schemaRecord = _getSchema(schemaUID);
        if (schemaRecord.registeredAt == 0) {
            revert InvalidSchema();
        }
    }

    /**
     * @dev Attests to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema to attest to.
     * @param data The arguments of the attestation requests.
     * @param attester The attesting account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return usedValue the msg.value used for attestations
     */
    function _attest(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData[] memory data,
        address attester,
        uint256 availableValue,
        bool last
    )
        private
        returns (uint256 usedValue)
    {
        _enforceExistingSchema(schemaUID);
        uint256 length = data.length;

        AttestationRecord[] memory attestations = new AttestationRecord[](
            length
        );
        uint256[] memory values = new uint256[](length);

        // caching the current time
        uint48 timeNow = _time();

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            AttestationRequestData memory request = data[i];
            // Ensure that either no expiration time was set or that it was set in the future.
            if (request.expirationTime != NO_EXPIRATION_TIME && request.expirationTime <= timeNow) {
                revert InvalidExpirationTime();
            }

            // scope to avoid stack too deep
            {
                ModuleRecord storage moduleRecord = _getModule(request.subject);

                // Ensure that attestation is for module that was registered.
                if (moduleRecord.implementation == address(0)) {
                    revert InvalidAttestation();
                }

                // Ensure that attestation for a module is using the modules resolver
                if (moduleRecord.resolverUID != resolverUID) {
                    revert InvalidAttestation();
                }
            }

            AttestationRecord memory attestation = AttestationRecord({
                schemaUID: schemaUID,
                time: timeNow,
                expirationTime: request.expirationTime,
                revocationTime: 0,
                subject: request.subject,
                attester: attester,
                data: request.data
            });

            // saving into contract storage
            _moduleToAuthorityToAttestations[request.subject][attester] = attestation;

            attestations[i] = attestation;

            values[i] = request.value;
            emit Attested(request.subject, attester, schemaUID);
        }

        usedValue =
            _resolveAttestations(resolverUID, attestations, values, false, availableValue, last);
    }

    /**
     * @dev Revokes an existing attestation to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema that was used to attest.
     * @param data The arguments of the revocation requests.
     * @param revoker The revoking account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _revoke(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        RevocationRequestData[] memory data,
        address revoker,
        uint256 availableValue,
        bool last
    )
        private
        returns (uint256)
    {
        _enforceExistingSchema(schemaUID);

        uint256 length = data.length;
        AttestationRecord[] memory attestations = new AttestationRecord[](
            length
        );
        uint256[] memory values = new uint256[](length);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            RevocationRequestData memory request = data[i];

            {
                AttestationRecord storage attestation =
                    _moduleToAuthorityToAttestations[request.subject][request.attester];

                // Ensure that we aren't attempting to revoke a non-existing attestation.
                if (attestation.data.length == 0) {
                    revert NotFound();
                }

                // Ensure that a wrong schema ID wasn't passed by accident.
                if (attestation.schemaUID != schemaUID) {
                    revert InvalidSchema();
                }

                // Allow only original attesters to revoke their attestations.
                if (attestation.attester != revoker) {
                    revert AccessDenied();
                }

                // Ensure that we aren't trying to revoke the same attestation twice.
                if (attestation.revocationTime != 0) {
                    revert AlreadyRevoked();
                }

                attestation.revocationTime = _time();

                attestations[i] = attestation;
                values[i] = request.value;
                emit Revoked(attestation.subject, revoker, attestation.schemaUID);
            }
        }

        return _resolveAttestations(resolverUID, attestations, values, true, availableValue, last);
    }

    /**
     * @dev Resolves a new attestation or a revocation of an existing attestation.
     *
     * @param resolverUID The schema of the attestation.
     * @param attestation The data of the attestation to make/revoke.
     * @param value An explicit ETH amount to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _resolveAttestation(
        ResolverUID resolverUID,
        AttestationRecord memory attestation,
        uint256 value,
        bool isRevocation,
        uint256 availableValue,
        bool last
    )
        private
        returns (uint256)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        ISchemaResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == address(0)) {
            // Ensure that we don't accept payments if there is no resolver.
            if (value != 0) {
                revert NotPayable();
            }

            return 0;
        }

        // Ensure that we don't accept payments which can't be forwarded to the resolver.
        if (value != 0 && !resolverContract.isPayable()) {
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
            if (!resolverContract.revoke{ value: value }(attestation)) {
                revert InvalidRevocation();
            }
        } else if (!resolverContract.attest{ value: value }(attestation)) {
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
     * @param resolverUID THe bytes32 uid of the resolver
     * @param attestations The data of the attestations to make/revoke.
     * @param values Explicit ETH amounts to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _resolveAttestations(
        ResolverUID resolverUID,
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
                resolverUID, attestations[0], values[0], isRevocation, availableValue, last
            );
        }
        ResolverRecord memory resolver = getResolver(resolverUID);

        ISchemaResolver resolverContract = resolver.resolver;
        if (address(resolverContract) == address(0)) {
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
            if (value != 0 && !resolverContract.isPayable()) {
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
            if (!resolverContract.multiRevoke{ value: totalUsedValue }(attestations, values)) {
                revert InvalidRevocations();
            }
        } else if (!resolverContract.multiAttest{ value: totalUsedValue }(attestations, values)) {
            revert InvalidAttestations();
        }

        if (last) {
            _refund(availableValue);
        }

        return totalUsedValue;
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

    function _getSchema(SchemaUID uid) internal view virtual returns (SchemaRecord storage);

    function getResolver(ResolverUID uid) public view virtual returns (ResolverRecord memory);

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
}
