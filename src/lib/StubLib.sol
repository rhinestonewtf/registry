// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRecord, ResolverRecord, SchemaRecord, ModuleRecord } from "../DataTypes.sol";
import { IExternalSchemaValidator } from "../external/IExternalSchemaValidator.sol";
import { IExternalResolver } from "../external/IExternalResolver.sol";
import { ZERO_ADDRESS, ZERO_TIMESTAMP } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * @title StubLib
 * @dev A library that interacts with IExternalResolver and IExternalSchemaValidator
 */
library StubLib {
    event ResolverRevocationError(IExternalResolver resolver);

    /**
     * @notice if Schema Validator is set, it will call validateSchema() on the validator
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

    function requireExternalResolverOnAttestation(AttestationRecord memory attestationRecord, ResolverRecord storage $resolver) internal {
        IExternalResolver resolverContract = $resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;
        if (resolverContract.resolveAttestation(attestationRecord) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnAttestation(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage $resolver
    )
        internal
    {
        IExternalResolver resolverContract = $resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

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

    function requireExternalResolverOnModuleRegistration(
        ModuleRecord memory moduleRecord,
        address moduleAddress,
        ResolverRecord storage $resolver
    )
        internal
    {
        IExternalResolver resolverContract = $resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;

        if (resolverContract.resolveModuleRegistration({ sender: msg.sender, moduleAddress: moduleAddress, record: moduleRecord }) == false)
        {
            revert IRegistry.ExternalError_ModuleRegistration();
        }
    }
}
