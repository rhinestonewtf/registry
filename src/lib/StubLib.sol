// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord, ResolverRecord, SchemaRecord, ModuleRecord } from "../DataTypes.sol";
import { IExternalSchemaValidator } from "../external/IExternalSchemaValidator.sol";
import { IExternalResolver } from "../external/IExternalResolver.sol";
import { ZERO_ADDRESS, ZERO_TIMESTAMP } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

// TODO: fix errors
library StubLib {
    function requireExternalSchemaValidation(
        AttestationRecord memory attestationRecord,
        SchemaRecord storage schema
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        if (schema.registeredAt == ZERO_TIMESTAMP) revert IRegistry.InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (
            address(validator) != ZERO_ADDRESS
                && validator.validateSchema(attestationRecord) == false
        ) {
            revert IRegistry.ExternalError_SchemaValidation();
        }
    }

    function requireExternalSchemaValidation(
        AttestationRecord[] memory attestationRecords,
        SchemaRecord storage schema
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        if (schema.registeredAt == ZERO_TIMESTAMP) revert IRegistry.InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (
            address(validator) != ZERO_ADDRESS
                && validator.validateSchema(attestationRecords) == false
        ) {
            revert IRegistry.ExternalError_SchemaValidation();
        }
    }

    function requireExternalResolverOnAttestation(
        AttestationRecord memory attestationRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;
        if (resolverContract.resolveAttestation(attestationRecord) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnAttestation(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnRevocation(
        AttestationRecord memory attestationRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;
        if (resolverContract.resolveRevocation(attestationRecord) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnRevocation(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnModuleRegistration(
        ModuleRecord memory moduleRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;

        if (resolverContract.resolveModuleRegistration(moduleRecord) == false) {
            revert IRegistry.ExternalError_ModuleRegistration();
        }
    }
}
