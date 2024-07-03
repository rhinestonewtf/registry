// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {
    AttestationDataRef,
    AttestationRecord,
    AttestationRequest,
    ModuleType,
    ResolverUID,
    RevocationRequest,
    SchemaUID
} from "../DataTypes.sol";
import { SchemaManager } from "./SchemaManager.sol";
import { ModuleManager } from "./ModuleManager.sol";
import { TrustManagerExternalAttesterList } from "./TrustManagerExternalAttesterList.sol";
import { StubLib } from "../lib/StubLib.sol";
import { AttestationLib } from "../lib/AttestationLib.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";
import { IRegistry } from "../IRegistry.sol";

import { EMPTY_ATTESTATION_REF, EMPTY_RESOLVER_UID, _time, ZERO_TIMESTAMP } from "../Common.sol";

/**
 * AttestationManager handles the registry's internal storage of new attestations and revocation of attestation
 * @dev This contract is abstract and provides internal utility functions to store attestations and revocations.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract AttestationManager is IRegistry, ModuleManager, SchemaManager, TrustManagerExternalAttesterList {
    using StubLib for *;
    using AttestationLib for AttestationDataRef;
    using AttestationLib for AttestationRequest;
    using AttestationLib for AttestationRequest[];
    using AttestationLib for address;
    using ModuleTypeLib for ModuleType[];

    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal $moduleToAttesterToAttestations;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Attestation                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Processes an attestation request and stores the attestation in the registry.
     * If the attestation was made for a module that was not registered, the function will revert.
     * function will get the external Schema Validator for the supplied SchemaUID
     *         and call it, if an external `IExternalSchemaValidator` was set
     * function will get the external `IExternalResolver` for the module - that the attestation is for
     *        and call it, if an external Resolver was set
     * @param attester The address of the attesting account.
     * @param schemaUID the UID of the schema that the attestation is made for
     * @param request AttestationRequest send by attester via `calldata`
     */
    function _attest(address attester, SchemaUID schemaUID, AttestationRequest calldata request) internal {
        (AttestationRecord memory record, ResolverUID resolverUID) =
            _storeAttestation({ schemaUID: schemaUID, attester: attester, request: request });

        record.requireExternalSchemaValidation({ $schema: schemas[schemaUID] });
        record.requireExternalResolverOnAttestation({ $resolver: $resolvers[resolverUID] });
    }

    /**
     * Processes an array of attestation requests  and stores the attestations in the registry.
     * If the attestation was made for a module that was not registered, the function will revert.
     * function will get the external Schema Validator for the supplied SchemaUID
     *         and call it, if an external IExternalSchemaValidator was set
     * function will get the external IExternalResolver for the module - that the attestation is for
     *        and call it, if an external Resolver was set
     */
    function _attest(address attester, SchemaUID schemaUID, AttestationRequest[] calldata requests) internal {
        uint256 length = requests.length;
        AttestationRecord[] memory records = new AttestationRecord[](length);
        // loop will check that the batched attestation is made ONLY for the same resolver
        ResolverUID resolverUID;
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            // save the attestation record into records array.
            (records[i], resolverUID_cache) = _storeAttestation({ schemaUID: schemaUID, attester: attester, request: requests[i] });
            // cache the first resolverUID and compare it to the rest
            // If the resolverUID is different, revert
            // @dev if you want to use different resolvers, make different attestation calls
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DifferentResolvers();
        }

        // Use StubLib to call schema Validation and resolver if needed
        records.requireExternalSchemaValidation({ $schema: schemas[schemaUID] });
        records.requireExternalResolverOnAttestation({ $resolver: $resolvers[resolverUID] });
    }

    /**
     * Stores an attestation in the registry storage.
     * The bytes encoded `AttestationRequest.Data` is not stored directly into the registry storage,
     * but rather stored with `SSTORE2`. `SSTORE2/SLOAD2` is writing and reading contract storage
     * paying a fraction of the cost, it uses contract code as storage, writing data takes the
     * form of contract creations and reading data uses `EXTCODECOPY`.
     * since attestation data is supposed to be immutable, it is a good candidate for `SSTORE2`
     *
     * @dev This function will revert if the same module is attested twice by the same attester.
     *      If you want to re-attest, you have to revoke your attestation first, and then attest again.
     *
     * @param attester The address of the attesting account.
     * @param request The AttestationRequest that was supplied via calldata
     * @return record The AttestationRecord of what was written into registry storage
     * @return resolverUID The resolverUID in charge for the module
     */
    function _storeAttestation(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest calldata request
    )
        internal
        returns (AttestationRecord memory record, ResolverUID resolverUID)
    {
        // if schema behind schemaUID is not registered, revert.
        if (schemas[schemaUID].registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();

        uint48 timeNow = _time();
        // Ensure that either no expiration time was set or that it was set in the future.
        if (request.expirationTime != ZERO_TIMESTAMP && request.expirationTime <= timeNow) {
            revert InvalidExpirationTime();
        }
        // caching module address.
        address module = request.moduleAddress;
        AttestationRecord storage $record = $getAttestation({ module: module, attester: attester });
        // If the attestation was already made for module, but not revoked, revert.
        if ($record.time != ZERO_TIMESTAMP && $record.revocationTime == ZERO_TIMESTAMP) {
            revert AlreadyAttested();
        }
        // SLOAD the resolverUID from the moduleRecord
        resolverUID = $moduleAddrToRecords[module].resolverUID;
        // Ensure that attestation is for module that was registered.
        if (resolverUID == EMPTY_RESOLVER_UID) {
            revert ModuleNotFoundInRegistry(module);
        }

        // use SSTORE2 to store the data in attestationRequest
        // this will revert, if in a batched attestation,
        // the same data is used twice by the same attester for the same module since the salt will be the same
        AttestationDataRef sstore2Pointer = request.sstore2({ salt: attester.sstore2Salt(module) });

        // write into memory allocated record, since that is the return value
        record = AttestationRecord({
            time: timeNow,
            expirationTime: request.expirationTime,
            revocationTime: uint48(ZERO_TIMESTAMP),
            moduleTypes: request.moduleTypes.pack(),
            schemaUID: schemaUID,
            moduleAddress: module,
            attester: attester,
            dataPointer: sstore2Pointer
        });
        // SSTORE attestation to registry storage
        $moduleToAttesterToAttestations[module][attester] = record;

        emit Attested({ moduleAddress: module, attester: attester, schemaUID: schemaUID, sstore2Pointer: sstore2Pointer });
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Revocation                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Revoke a single Revocation Request
     * This function will write the `RevocationRequest` into storage, and get the stored `RevocationRecord` back,
     * and pass the `RevocationRecord` to the resolver to check if the revocation is valid
     */
    function _revoke(address attester, RevocationRequest calldata request) internal {
        (AttestationRecord memory record, ResolverUID resolverUID) = _storeRevocation(attester, request);
        record.tryExternalResolverOnRevocation({ $resolver: $resolvers[resolverUID] });
    }

    /**
     * Revoke an array Revocation Request
     * This function will write the `RevocationRequest` into storage, and get the stored `RevocationRecord` back,
     * and pass the `RevocationRecord` to the resolver to check if the revocation is valid
     */
    function _revoke(address attester, RevocationRequest[] calldata requests) internal {
        uint256 length = requests.length;
        AttestationRecord[] memory records = new AttestationRecord[](length);
        ResolverUID resolverUID;
        // loop over revocation requests. This function will revert if different resolverUIDs
        // are responsible for the modules that are subject of the revocation. This is to reduce complexity
        // @dev if you want to revoke attestations from different resolvers, make different revocation calls
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            (records[i], resolverUID_cache) = _storeRevocation(attester, requests[i]);
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DifferentResolvers();
        }

        // No schema validation required during revocation. The attestation data was already checked against
        records.tryExternalResolverOnRevocation({ $resolver: $resolvers[resolverUID] });
    }

    /**
     * Gets the AttestationRecord for the supplied RevocationRequest and stores the revocation time in the registry storage
     * @param revoker The address of the attesting account.
     * @param request The AttestationRequest that was supplied via calldata
     * @return record The AttestationRecord of what was written into registry storage
     * @return resolverUID The resolverUID in charge for the module
     */
    function _storeRevocation(
        address revoker,
        RevocationRequest calldata request
    )
        internal
        returns (AttestationRecord memory record, ResolverUID resolverUID)
    {
        AttestationRecord storage $attestation = $moduleToAttesterToAttestations[request.moduleAddress][revoker];

        // SLOAD entire record. This will later be passed to the resolver
        record = $attestation;
        resolverUID = $moduleAddrToRecords[request.moduleAddress].resolverUID;

        // Ensure that we aren't attempting to revoke a non-existing attestation.
        if (record.dataPointer == EMPTY_ATTESTATION_REF) {
            revert AttestationNotFound();
        }

        // Allow only original attesters to revoke their attestations.
        if (record.attester != revoker) {
            revert AccessDenied();
        }

        // Ensure that we aren't trying to revoke the same attestation twice.
        if (record.revocationTime != ZERO_TIMESTAMP) {
            revert AlreadyRevoked();
        }

        // SSTORE revocation time to registry storage
        // set revocation time to NOW
        $attestation.revocationTime = _time();

        emit Revoked({ moduleAddress: request.moduleAddress, revoker: revoker, schema: record.schemaUID });
    }

    /**
     * Returns a storage reference to attestation records for the given module and attesters.
     * This function is expected to be used by `TrustManager` and `TrustManagerExternalAttesterList`
     */
    function $getAttestation(address module, address attester) internal view override returns (AttestationRecord storage $attestation) {
        $attestation = $moduleToAttesterToAttestations[module][attester];
    }
}
