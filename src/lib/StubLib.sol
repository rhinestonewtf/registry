// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord, ResolverRecord, SchemaRecord, ModuleRecord } from "../DataTypes.sol";
import { IExternalSchemaValidator } from "../external/IExternalSchemaValidator.sol";
import { IExternalResolver } from "../external/IExternalResolver.sol";
import { ZERO_ADDRESS, ZERO_TIMESTAMP } from "../Common.sol";

// TODO: fix errors
library StubLib {
    error InvalidDeployment();
    error InvalidSchema();

    function requireExternalSchemaValidation(
        AttestationRecord memory attestationRecord,
        SchemaRecord storage schema
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (
            address(validator) != ZERO_ADDRESS
                && validator.validateSchema(attestationRecord) == false
        ) {
            // revert if IExternalSchemaValidator returns false
            revert();
            // if (!success) { // If call reverts
            //   // If there is return data, the call reverted without a reason or a custom error.
            //   if (result.length == 0) revert();
            //   assembly {
            //     // We use Yul's revert() to bubble up errors from the target contract.
            //     revert(add(32, result), mload(result))
            //   }
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
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (
            address(validator) != ZERO_ADDRESS
                && validator.validateSchema(attestationRecords) == false
        ) {
            revert();
        }
    }

    function requireExternalResolverCheck(
        AttestationRecord memory attestationRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;
        if (resolverContract.resolveAttestation(attestationRecord) == false) {
            revert();
        }
    }

    function requireExternalResolverCheck(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert();
        }
    }

    function requireExternalResolverCheck(
        ModuleRecord memory moduleRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;

        if (resolverContract.resolveModuleRegistration(moduleRecord) == false) {
            revert();
        }
    }
}
