// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    AttestationRequest,
    AttestationRecord,
    AttestationDataRef,
    RevocationRequest,
    ModuleRecord,
    SchemaUID,
    ResolverUID,
    ModuleType,
    PackedModuleTypes
} from "../DataTypes.sol";
import { ResolverManager } from "./ResolverManager.sol";
import { SchemaManager } from "./SchemaManager.sol";
import { ModuleManager } from "./ModuleManager.sol";
import { TrustManager } from "./TrustManager.sol";
import { StubLib } from "../lib/StubLib.sol";
import { AttestationLib } from "../lib/AttestationLib.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";

import { EMPTY_RESOLVER_UID, ZERO_ADDRESS, ZERO_TIMESTAMP, _time } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

abstract contract AttestationManager is IRegistry, TrustManager, ModuleManager, SchemaManager {
    using StubLib for *;
    using AttestationLib for *; // TODO: specify what
    using ModuleTypeLib for ModuleType[];

    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal
        _moduleToAttesterToAttestations;

    function _revoke(address attester, RevocationRequest calldata request) internal {
        (AttestationRecord memory record, ResolverUID resolverUID) =
            _storeRevocation(attester, request);
        record.requireExternalResolverOnRevocation({ resolver: resolvers[resolverUID] });
    }

    function _revoke(address attester, RevocationRequest[] calldata requests) internal {
        uint256 length = requests.length;
        AttestationRecord[] memory records = new AttestationRecord[](length);
        ResolverUID resolverUID;
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            (records[i], resolverUID_cache) = _storeRevocation(attester, requests[i]);
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DifferentResolvers();
        }

        // No schema validation required during revocation. the attestation data was already checked against

        // TODO: what if this fails? it would stop attesters from revoking. Is this wanted behavior?
        records.requireExternalResolverOnRevocation({ resolver: resolvers[resolverUID] });
    }

    function _attest(
        address attester,
        SchemaUID schemaUID,
        AttestationRequest calldata request
    )
        internal
    {
        (AttestationRecord memory record, ResolverUID resolverUID) =
            _storeAttestation({ schemaUID: schemaUID, attester: attester, request: request });

        record.requireExternalSchemaValidation({ schema: schemas[schemaUID] });
        record.requireExternalResolverOnAttestation({ resolver: resolvers[resolverUID] });
    }

    function _attest(
        address attester,
        SchemaUID schemaUID,
        AttestationRequest[] calldata requests
    )
        internal
    {
        uint256 length = requests.length;
        AttestationRecord[] memory records = new AttestationRecord[](length);
        // loop will check that the batched attestation is made ONLY for the same resolver
        // @dev if you want to use different resolvers, make different attestation calls
        ResolverUID resolverUID;
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            (records[i], resolverUID_cache) = _storeAttestation({
                schemaUID: schemaUID,
                attester: attester,
                request: requests[i]
            });
            // cache the first resolverUID and compare it to the rest
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DifferentResolvers();
        }

        records.requireExternalSchemaValidation({ schema: schemas[schemaUID] });
        records.requireExternalResolverOnAttestation({ resolver: resolvers[resolverUID] });
    }

    function _storeAttestation(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest calldata request
    )
        internal
        returns (AttestationRecord memory record, ResolverUID resolverUID)
    {
        uint48 timeNow = _time();
        // Ensure that either no expiration time was set or that it was set in the future.
        if (request.expirationTime != ZERO_TIMESTAMP && request.expirationTime <= timeNow) {
            revert InvalidExpirationTime();
        }
        // caching module address.
        address module = request.moduleAddr;
        ModuleRecord storage moduleRecord = _modules[request.moduleAddr];
        // Ensure that attestation is for module that was registered.
        if (moduleRecord.resolverUID != EMPTY_RESOLVER_UID) {
            revert InvalidAttestation();
        }
        resolverUID = moduleRecord.resolverUID;

        // get salt used for SSTORE2 to avoid collisions during CREATE2
        bytes32 attestationSalt = attester.sstore2Salt(module);
        AttestationDataRef sstore2Pointer = request.sstore2(attestationSalt);

        record = AttestationRecord({
            time: timeNow,
            expirationTime: request.expirationTime,
            revocationTime: uint48(ZERO_TIMESTAMP),
            moduleTypes: request.moduleTypes.pack(),
            schemaUID: schemaUID,
            moduleAddr: module,
            attester: attester,
            dataPointer: sstore2Pointer
        });
        // SSTORE attestation to registry storage
        _moduleToAttesterToAttestations[request.moduleAddr][attester] = record;

        emit Attested(module, attester, schemaUID, sstore2Pointer);
    }

    function _storeRevocation(
        address revoker,
        RevocationRequest calldata request
    )
        internal
        returns (AttestationRecord memory attestation, ResolverUID resolverUID)
    {
        AttestationRecord storage attestationStorage =
            _moduleToAttesterToAttestations[request.moduleAddr][revoker];
        // SSLOAD entire record. This will later be passed to the resolver
        attestation = attestationStorage;

        // Ensure that we aren't attempting to revoke a non-existing attestation.
        if (AttestationDataRef.unwrap(attestation.dataPointer) == ZERO_ADDRESS) {
            revert AttestationNotFound();
        }

        // Allow only original attesters to revoke their attestations.
        if (attestation.attester != revoker) {
            revert AccessDenied();
        }

        // Ensure that we aren't trying to revoke the same attestation twice.
        if (attestation.revocationTime != ZERO_TIMESTAMP) {
            revert AlreadyRevoked();
        }

        resolverUID = _modules[attestation.moduleAddr].resolverUID;
        attestationStorage.revocationTime = _time();
        // set revocation time to NOW
        emit Revoked({
            moduleAddr: attestation.moduleAddr,
            revoker: revoker,
            schema: attestation.schemaUID
        });
    }

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        override
        returns (AttestationRecord storage)
    {
        return _moduleToAttesterToAttestations[module][attester];
    }
}
