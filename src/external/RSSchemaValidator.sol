// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IExternalSchemaValidator } from "src/external/IExternalSchemaValidator.sol";
import "src/DataTypes.sol";

contract RSSchemaValidator is IExternalSchemaValidator {
    error InvalidAttestationData();

    function getSchema() external returns (string memory schema) {
        return
        "(enum ERC7579ModuleType (None,Validator,Executor,Fallback,Hook),struct ModuleTypeAttributes (ERC7579ModuleType moduleType,bytes encodedAttributes),struct ModuleAttributes (address moduleAddress,bytes packedAttributes,ModuleTypeAttributes[] typeAttributes,bytes packedExternalDependency),enum SignatureType (None,SECP256K1,ERC1271),struct Auditor (string name,string uri,string[] authors),struct Signature (SignatureType sigType,address signer,bytes signatureData,bytes32 hash),struct AuditSummary (string title,Auditor auditor,ModuleAttributes moduleAttributes,Signature signature))";
    }

    function validateSchema(AttestationRecord calldata attestation) public override returns (bool valid) {
        return true;
    }

    function validateSchema(AttestationRecord[] calldata attestations) external override returns (bool) {
        return true;
    }

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return (interfaceID == type(IExternalSchemaValidator).interfaceId);
    }
}
