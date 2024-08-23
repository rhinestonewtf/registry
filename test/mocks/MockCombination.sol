// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/external/IExternalResolver.sol";
import "src/external/IExternalSchemaValidator.sol";
import { IRegistry, SchemaUID, AttestationRequest } from "src/IRegistry.sol";

contract MockCombination is IExternalResolver, IExternalSchemaValidator {
    bool immutable returnVal;

    event AttestationCalled();
    event RevokeCalled();
    event ModuleCalled();

    constructor(bool ret) {
        returnVal = ret;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     RESOLVER
    //////////////////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        if (interfaceId == type(IExternalResolver).interfaceId || interfaceId == type(IExternalSchemaValidator).interfaceId) return true;
    }

    function resolveAttestation(AttestationRecord calldata attestation) external payable override returns (bool) {
        emit AttestationCalled();
        return returnVal;
    }

    function resolveAttestation(AttestationRecord[] calldata attestation) external payable override returns (bool) {
        emit AttestationCalled();
        return returnVal;
    }

    function resolveRevocation(AttestationRecord calldata attestation) external payable override returns (bool) {
        emit RevokeCalled();
        return returnVal;
    }

    function resolveRevocation(AttestationRecord[] calldata attestation) external payable override returns (bool) {
        emit RevokeCalled();
        return returnVal;
    }

    function resolveModuleRegistration(
        address sender,
        address moduleRecord,
        ModuleRecord calldata record,
        bytes calldata resolverContext
    )
        external
        payable
        override
        returns (bool)
    {
        emit ModuleCalled();
        return returnVal;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                SCHEMA VALIDATOR
    //////////////////////////////////////////////////////////////////////////*/

    function validateSchema(AttestationRecord calldata attestation) external view override returns (bool) {
        return returnVal;
    }

    function validateSchema(AttestationRecord[] calldata attestations) external view override returns (bool) {
        return returnVal;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MOCK ATTESTER
    //////////////////////////////////////////////////////////////////////////*/

    function attest(IRegistry registry, SchemaUID schemaUID, AttestationRequest calldata request) external payable returns (bool) {
        registry.attest(schemaUID, request);
    }
}
