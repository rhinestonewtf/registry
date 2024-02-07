// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    AttestationDataRef,
    AttestationRecord,
    AttestationRequest,
    ModuleRecord,
    ModuleType,
    ResolverUID,
    RevocationRequest,
    SchemaUID
} from "../DataTypes.sol";
import { SchemaManager } from "./SchemaManager.sol";
import { ModuleManager } from "./ModuleManager.sol";
import { TrustManager } from "./TrustManager.sol";
import { StubLib } from "../lib/StubLib.sol";
import { AttestationLib } from "../lib/AttestationLib.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";

import { EMPTY_ATTESTATION_REF, EMPTY_RESOLVER_UID, _time, ZERO_TIMESTAMP } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

abstract contract AttestationManager is IRegistry, ModuleManager, SchemaManager, TrustManager {
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

    /**
     * Processes an attestation request and stores the attestation in the registry.
     * If the attestation was made for a module that was not registered, the function will revert.
     * function will get the external Schema Validator for the supplied SchemaUID
     *         and call it, if an external IExternalSchemaValidator was set
     * function will get the external IExternalResolver for the module - that the attestation is for
     *        and call it, if an external Resolver was set
     */
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
        ResolverUID resolverUID;
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            (records[i], resolverUID_cache) = _storeAttestation({
                schemaUID: schemaUID,
                attester: attester,
                request: requests[i]
            });
            // cache the first resolverUID and compare it to the rest
            // If the resolverUID is different, revert
            // @dev if you want to use different resolvers, make different attestation calls
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DifferentResolvers();
        }

        records.requireExternalSchemaValidation({ schema: schemas[schemaUID] });
        records.requireExternalResolverOnAttestation({ resolver: resolvers[resolverUID] });
    }

    /**
     * Stores an attestation in the registry.
     */
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
            moduleTypes: request.moduleTypes.packCalldata(),
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

        // SLOAD entire record. This will later be passed to the resolver
        attestation = attestationStorage;
        resolverUID = _modules[request.moduleAddr].resolverUID;

        // Ensure that we aren't attempting to revoke a non-existing attestation.
        if (attestation.dataPointer == EMPTY_ATTESTATION_REF) {
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

        // SSTORE revocation time to registry storage
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
