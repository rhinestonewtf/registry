// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";

import {
    IAttestation,
    AttestationRequest,
    MultiAttestationRequest,
    RevocationRequest,
    MultiRevocationRequest,
    AttestationLib
} from "../interface/IAttestation.sol";
import { SchemaUID, ResolverUID, SchemaRecord, ISchemaValidator } from "./Schema.sol";
import { ModuleRecord } from "./Module.sol";
import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import {
    ZERO_ADDRESS,
    AccessDenied,
    NotFound,
    ZERO_TIMESTAMP,
    InvalidSchema,
    _time
} from "../Common.sol";

import {
    AttestationDataRef,
    AttestationRecord,
    AttestationRequestData,
    RevocationRequestData,
    writeAttestationData
} from "../DataTypes.sol";
import { AttestationResolve } from "./AttestationResolve.sol";

contract Attestation {
    using ModuleDeploymentLib for address;

    // Mapping of module addresses to attester addresses to their attestation records.
    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal
        _moduleToAttesterToAttestations;

    function attest(SchemaUID schemaUID, AttestationRequestData calldata request) external {
        _attestAndCheckExternal(msg.sender, schemaUID, request);
    }

    function attest(SchemaUID schemaUID, AttestationRequestData[] calldata requests) external {
        _attestAndCheckExternal(msg.sender, schemaUID, requests);
    }

    function _attestAndCheckExternal(
        address attester,
        SchemaUID schemaUID,
        AttestationRequestData calldata request
    )
        internal
    {
        AttestationRecord memory record = _storeAttestation({
            schemaUID: schemaUID,
            attester: attester,
            attestationRequestData: request
        });

        // check if schema exists and is valid. This will revert if validtor returns false
        _requireSchemaCheck({ schemaUID: schemaUID, record: record });

        // trigger the resolver procedure
        _requireExternalResolveAttestation({ resolverUID: moduleRecord.resolverUID, record: record });
    }

    function _attestAndCheckExternal(
        address attester,
        SchemaUID schemaUID,
        AttestationRequestData[] calldata requests
    )
        internal
    {
        uint256 length = requests.length;
        AttestationRecord[] memory attestationRecords = new AttestationRecord[](length);

        for (uint256 i; i < length; i++) {
            attestationRecord[i] = _storeAttestation({
                schemaUID: schemaUID,
                attester: attester,
                attestationRequestData: requests[i]
            });
        }

        // check if schema exists and is valid. This will revert if validtor returns false
        _requireSchemaCheck({ schemaUID: schemaUID, records: attestationRecords });

        // trigger the resolver procedure
        _requireExternalResolveAttestation({
            resolverUID: moduleRecord.resolverUID,
            records: attestationRecords
        });
    }

    function _storeAttestation(
        SchemaUID schemaUID,
        address attester,
        AttestationRequestData calldata attestationRequestData
    )
        internal
        returns (AttestationRecord memory record)
    {
        AttestationRecord storage recordStorage = _moduleToAttesterToAttestations[module][attester];
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
        if (moduleRecord.resolverUID != RESOLVER_UID_ZERO) {
            revert ModuleNotRegistered();
        }

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
        recordStorage = record;

        emit Attested(module, attester, schemaUID, sstore2Pointer);
    }

    function _requireSchemaCheck(
        SchemaUID schemaUID,
        AttestationRecord memory record
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema({ schemaUID: schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS && validator.validateSchema(record) == false) {
            // revert if ISchemaValidator returns false
            revert InvalidAttestation();
        }
    }

    function _requireSchemaCheck(
        SchemaUID schemaUID,
        AttestationRecord[] memory records
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema({ schemaUID: schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS && validator.validateSchema(records) == false) {
            // revert if ISchemaValidator returns false
            revert InvalidAttestation();
        }
    }
}
