// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRecord, ResolverRecord, SchemaRecord, ModuleRecord } from "../DataTypes.sol";
import { IExternalSchemaValidator } from "../external/IExternalSchemaValidator.sol";
import { IExternalResolver } from "../external/IExternalResolver.sol";
import { ZERO_ADDRESS, ZERO_TIMESTAMP } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * Helper library for interacting with `IExternalResolver` and `IExternalSchemaValidator`
 * @dev if a certain resolver or validator is not set, the function will return without reverting
 */
library StubLib {
    event ResolverRevocationError(IExternalResolver resolver);

    /**
     * Calls an external schema validator contract to validate the schema for a single attestation
     * @dev if Schema Validator is set, it will call `validateSchema()` on the `IExternalSchemaValidator` contract
     * @param attestationRecord the data record that will be written into registry for this attestation
     * @param $schema the storage reference of the schema record
     */
    function requireExternalSchemaValidation(AttestationRecord memory attestationRecord, SchemaRecord storage $schema) internal {
        // only run this function if the selected schemaUID exists
        if ($schema.registeredAt == ZERO_TIMESTAMP) revert IRegistry.InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = $schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS && validator.validateSchema(attestationRecord) == false) {
            revert IRegistry.ExternalError_SchemaValidation();
        }
    }

    /**
     * Calls an external schema validator contract to validate the schema for multiple attestation
     * @dev if Schema Validator is set, it will call `validateSchema()` on the `IExternalSchemaValidator` contract
     * @param attestationRecords the data records that will be written into registry for the attestations
     * @param $schema the storage reference of the schema record
     */
    function requireExternalSchemaValidation(AttestationRecord[] memory attestationRecords, SchemaRecord storage $schema) internal {
        // only run this function if the selected schemaUID exists
        if ($schema.registeredAt == ZERO_TIMESTAMP) revert IRegistry.InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = $schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS && validator.validateSchema(attestationRecords) == false) {
            revert IRegistry.ExternalError_SchemaValidation();
        }
    }

    /**
     * Calls an external resolver contract to resolve a single attestation
     * @dev if a resolver is set, it will call `resolveAttestation()` on the `IExternalResolver` contract
     * @param attestationRecord the data record that will be written into registry for the attestation
     * @param $resolver the storage reference of the resolver record used for this attestation
     */
    function requireExternalResolverOnAttestation(AttestationRecord memory attestationRecord, ResolverRecord storage $resolver) internal {
        IExternalResolver resolverContract = $resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS && resolverContract.resolveAttestation(attestationRecord) == false) {
            revert IRegistry.ExternalError_ResolveAttestation();
        }
    }

    /**
     * Calls an external resolver contract to resolve multiple attestations
     * @dev if a resolver is set, it will call `resolveAttestation()` on the `IExternalResolver` contract
     * @param attestationRecords the data records that will be written into registry for the attestation
     * @param $resolver the storage reference of the resolver record used for this attestation
     */
    function requireExternalResolverOnAttestation(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage $resolver
    )
        internal
    {
        IExternalResolver resolverContract = $resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert IRegistry.ExternalError_ResolveAttestation();
        }
    }

    /**
     * Calls an external resolver contract to resolve a single revocation
     * @dev if a resolver is set, it will call `resolveRevocation()` on the `IExternalResolver` contract
     * @dev if the resolver contract reverts, the function will return without reverting.
     * This prevents Resolvers from denying revocations
     * @param attestationRecord the data records of the attestation that will be revoked
     * @param $resolver the storage reference of the resolver record used for this attestation
     */
    function tryExternalResolverOnRevocation(
        AttestationRecord memory attestationRecord,
        ResolverRecord storage $resolver
    )
        internal
        returns (bool resolved)
    {
        IExternalResolver resolverContract = $resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return true;
        try resolverContract.resolveRevocation(attestationRecord) returns (bool _resolved) {
            if (_resolved) return true;
        } catch {
            emit ResolverRevocationError(resolverContract);
            return false;
        }
    }

    /**
     * Calls an external resolver contract to resolve multiple revocation
     * @dev if a resolver is set, it will call `resolveRevocation()` on the `IExternalResolver` contract
     * @dev if the resolver contract reverts, the function will return without reverting.
     * This prevents Resolvers to stop DoS revocations
     * @param attestationRecords the data records of the attestations that will be revoked
     * @param $resolver the storage reference of the resolver record used for this attestation
     */
    function tryExternalResolverOnRevocation(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage $resolver
    )
        internal
        returns (bool resolved)
    {
        IExternalResolver resolverContract = $resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return true;
        try resolverContract.resolveRevocation(attestationRecords) returns (bool _resolved) {
            if (_resolved) return true;
        } catch {
            emit ResolverRevocationError(resolverContract);
            return false;
        }
    }

    /**
     * Calls an external resolver contract to resolve a module registration
     * @dev if a resolver is set, it will call `resolveModuleRegistration()` on the `IExternalResolver` contract
     * @param moduleRecord the module record that will be written into registry for the module registration
     * @param moduleAddress the address of the module to register.
     *       at the point of this call, the module MUST be already deployed (could be within the current transaction)
     * @param $resolver the storage reference of the resolver record used for this module registration
     */
    function requireExternalResolverOnModuleRegistration(
        ModuleRecord memory moduleRecord,
        address moduleAddress,
        ResolverRecord storage $resolver,
        bytes calldata resolverContext
    )
        internal
    {
        IExternalResolver resolverContract = $resolver.resolver;

        if (
            address(resolverContract) != ZERO_ADDRESS
                && resolverContract.resolveModuleRegistration({
                    sender: msg.sender,
                    moduleAddress: moduleAddress,
                    record: moduleRecord,
                    resolverContext: resolverContext
                }) == false
        ) {
            revert IRegistry.ExternalError_ModuleRegistration();
        }
    }
}
