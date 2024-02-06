// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord, ResolverRecord } from "../DataTypes.sol";

library StubLib {
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
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS && validator.validateSchema(requestData) == false) {
            // revert if ISchemaValidator returns false
            revert InvalidAttestation();
        }
    }

    function _requireSchemaCheck(
        AttestationRecord[] memory attestationRecords,
        SchemaRecord storage schema
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (
            address(validator) != ZERO_ADDRESS
                && validator.validateSchema(attestationRecords) == false
        ) {
            revert InvalidAttestation();
        }
    }

    function requireExternalResolverCheck(
        AttestationRecord memory attestationRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IResolver resolverContract = resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;
        if (resolverContract.resolveAttestation(attestationRecord) == false) {
            revert InvalidAttestation();
        }
    }

    function requireExternalResolver(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage resolver
    )
        internal
    {
        IResolver resolverContract = resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert InvalidAttestation();
        }
    }
}
