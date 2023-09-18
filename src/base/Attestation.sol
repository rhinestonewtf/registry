// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { EIP712Verifier } from "./EIP712Verifier.sol";
import "../interface/IAttestation.sol";
import "./Schema.sol";
import "./Module.sol";

import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";

import {
    ZERO_ADDRESS,
    AccessDenied,
    NotFound,
    NO_EXPIRATION_TIME,
    InvalidLength,
    uncheckedInc,
    InvalidSchema,
    _time
} from "../Common.sol";

import { AttestationDataRef, writeAttestationData, readAttestationData } from "../DataTypes.sol";

import { AttestationResolve } from "./AttestationResolve.sol";
/**
 * @title Module
 *
 * @author zeroknots
 */

abstract contract Attestation is IAttestation, AttestationResolve {
    using ModuleDeploymentLib for address;

    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal
        _moduleToAttesterToAttestations;

    constructor(string memory name, string memory version) EIP712Verifier(name, version) { }

    /*//////////////////////////////////////////////////////////////
                              ATTEST
    //////////////////////////////////////////////////////////////*/
    function attest(AttestationRequest calldata request) external payable {
        AttestationRequestData calldata requestData = request.data;

        ModuleRecord storage moduleRecord = _getModule(request.data.subject);
        ResolverUID resolverUID = moduleRecord.resolverUID;

        AttestationRecord[] memory attestations = new AttestationRecord[](1);
        uint256[] memory values = new uint256[](1);

        (attestations[0], values[0]) =
            _writeAttestation(request.schemaUID, resolverUID, requestData, msg.sender, _time());

        uint256 usedValue =
            _resolveAttestations(resolverUID, attestations, values, false, msg.value, true);
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

    /*//////////////////////////////////////////////////////////////
                              REVOKE
    //////////////////////////////////////////////////////////////*/

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
        uint256 requestsLength = multiRequests.length;

        // should cache length
        for (uint256 i; i < requestsLength; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == requestsLength - 1;
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
        AttestationRequestData[] calldata data,
        address attester,
        uint256 availableValue,
        bool last
    )
        internal
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
            (attestations[i], values[i]) = _writeAttestation({
                schemaUID: schemaUID,
                resolverUID: resolverUID,
                request: data[i],
                attester: attester,
                timeNow: timeNow
            });
        }

        usedValue =
            _resolveAttestations(resolverUID, attestations, values, false, availableValue, last);
    }

    function _writeAttestation(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData calldata request,
        address attester,
        uint48 timeNow
    )
        internal
        returns (AttestationRecord memory attestation, uint256 value)
    {
        // Ensure that either no expiration time was set or that it was set in the future.
        if (request.expirationTime != NO_EXPIRATION_TIME && request.expirationTime <= timeNow) {
            revert InvalidExpirationTime();
        }
        address module = request.subject;
        ModuleRecord storage moduleRecord = _getModule(module);

        // Ensure that attestation is for module that was registered.
        if (moduleRecord.implementation == ZERO_ADDRESS) {
            revert InvalidAttestation();
        }

        // Ensure that attestation for a module is using the modules resolver
        if (moduleRecord.resolverUID != resolverUID) {
            revert InvalidAttestation();
        }
        bytes32 attestationSalt = _getAttestationSSTORESalt(attester, module);
        attestation = AttestationRecord({
            schemaUID: schemaUID,
            subject: module,
            attester: attester,
            time: timeNow,
            expirationTime: request.expirationTime,
            revocationTime: 0,
            dataPointer: writeAttestationData(request.data, attestationSalt)
        });
        value = request.value;

        // SSTORE attestation on registry storage
        _moduleToAttesterToAttestations[module][attester] = attestation;
        emit Attested(module, attester, schemaUID);
    }

    function _getAttestationSSTORESalt(
        address attester,
        address module
    )
        private
        returns (bytes32 dataPointerSalt)
    {
        dataPointerSalt =
            keccak256(abi.encodePacked(module, attester, block.timestamp, block.chainid));
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
        internal
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
                    _moduleToAttesterToAttestations[request.subject][request.attester];

                // Ensure that we aren't attempting to revoke a non-existing attestation.
                if (AttestationDataRef.unwrap(attestation.dataPointer) == ZERO_ADDRESS) {
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

    function _enforceExistingSchema(SchemaUID schemaUID) private view {
        SchemaRecord storage schemaRecord = _getSchema(schemaUID);
        if (schemaRecord.registeredAt == 0) {
            revert InvalidSchema();
        }
    }

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage)
    {
        return _moduleToAttesterToAttestations[module][attester];
    }
}
