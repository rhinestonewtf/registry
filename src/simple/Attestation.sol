// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord } from "../DataTypes.sol";
import { ResolverManager } from "./ResolverManager.sol";
import { SchemaManager } from "./SchemaManager.sol";
import { StubLib } from "../lib/StubLib.sol";

contract Attestation is ResolverManager, SchemaManager {
    using StubLib for AttestationRecord;
    using StubLib for AttestationRecord[];

    error DifferentResolvers();

    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal
        _moduleToAttesterToAttestations;

    function attest(SchemaUID schemaUID, AttestationRequestData calldata request) external {
        _attest(msg.sender, schemaUID, request);
    }

    function attest(SchemaUID schemaUID, AttestationRequestData[] calldata requests) external {
        _attest(msg.sender, schemaUID, requests);
    }

    function revoke(address module) external { }

    function _revoke(address attester, address module) internal {
        _storeRevocation(attester, module);
    }

    function _attest(
        address attester,
        SchemaUID schemaUID,
        AttestationRequestData calldata request
    )
        internal
    {
        (AttestationRecord memory record, ResolverUID resolverUID) = _storeAttestation({
            schemaUID: schemaUID,
            attester: attester,
            attestationRequestData: request
        });

        record.requireExternalSchemaValidation({ schema: schema[schemaUID] });
        record.requireExternalResolverCheck({ resolver: resolver[resolverUID] });
    }

    function _attest(
        address attester,
        SchemaUID schemaUID,
        AttestationRequestData[] calldata requests
    )
        internal
    {
        uint256 length = requests.length;
        AttetationRecord[] memory records = new AttestationRecord[](length);
        // loop will check that the batched attestation is made ONLY for the same resolver
        // @dev if you want to use different resolvers, make different attestation calls
        ResolverUID resolverUID;
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            (records[i], resolverUID_cache) = _storeAttestation({
                schemaUID: schemaUID,
                attester: attester,
                attestationRequestData: requests[i]
            });
            // cache the first resolverUID and compare it to the rest
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DiffernetResolvers();
        }

        records.requireExternalSchemaValidation({ schema: schema[schemaUID] });
        records.requireExternalResolverCheck({ resolver: resolver[resolverUID] });
    }

    function _storeAttestation(
        SchemaUID schemaUID,
        address attester,
        AttestationRequestData calldata attestationRequestData
    )
        internal
        returns (AttestationRecord memory record, ResolverUID resolverUID)
    {
        AttestationRecord storage record = _moduleToAttesterToAttestations[module][attester];
        uint48 timeNow = _time();
        // Ensure that either no expiration time was set or that it was set in the future.
        if (
            attestationRequestData.expirationTime != ZERO_TIMESTAMP
                && attestationRequestData.expirationTime <= timeNow
        ) {
            revert InvalidExpirationTime();
        }
        // caching module address.
        address module = attestationRequestData.moduleAddr;
        ModuleRecord storage moduleRecord = _getModule({ moduleAddress: module });

        // Ensure that attestation is for module that was registered.
        if (moduleRecord.implementation == ZERO_ADDRESS) {
            revert InvalidAttestation();
        }
        resolverUID = moduleRecord.resolverUID;

        // get salt used for SSTORE2 to avoid collisions during CREATE2
        bytes32 attestationSalt = AttestationLib.attestationSalt(attester, module);
        AttestationDataRef sstore2Pointer = writeAttestationData({
            attestationData: attestationRequestData.data,
            salt: attestationSalt
        });

        // SSTORE attestation on registry storage
        record = AttestationRecord({
            schemaUID: schemaUID,
            moduleAddr: module,
            attester: attester,
            time: timeNow,
            expirationTime: attestationRequestData.expirationTime,
            revocationTime: uint48(ZERO_TIMESTAMP),
            dataPointer: sstore2Pointer
        });

        emit Attested(module, attester, schemaUID, sstore2Pointer);
    }

    function _storeRevocation(
        address attester,
        address moduleAddr
    )
        internal
        returns (AttestationRecord memory attestationRecord, ResolverUID resolverUID)
    {
        AttestationRecord storage attestation =
            _moduleToAttesterToAttestations[moduleAddr][attester];

        // Ensure that we aren't attempting to revoke a non-existing attestation.
        if (AttestationDataRef.unwrap(attestation.dataPointer) == ZERO_ADDRESS) {
            revert NotFound();
        }

        // Allow only original attesters to revoke their attestations.
        if (attestation.attester != revoker) {
            revert AccessDenied();
        }

        // Ensure that we aren't trying to revoke the same attestation twice.
        if (attestation.revocationTime != ZERO_TIMESTAMP) {
            revert AlreadyRevoked();
        }

        // set revocation time to NOW
        attestation.revocationTime = _time();
        emit Revoked({
            moduleAddr: attestation.moduleAddr,
            revoker: revoker,
            schema: attestation.schemaUID
        });
        resolverUID = _getModule({ moduleAddress: moduleAddr }).resolverUID;
    }
}
