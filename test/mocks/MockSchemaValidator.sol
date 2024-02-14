// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/external/IExternalSchemaValidator.sol";

contract MockSchemaValidator is IExternalSchemaValidator {
    bool immutable returnVal;

    constructor(bool ret) {
        returnVal = ret;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        if (interfaceId == type(IExternalSchemaValidator).interfaceId) return true;
    }

    function validateSchema(AttestationRecord calldata attestation) external view override returns (bool) {
        return returnVal;
    }

    function validateSchema(AttestationRecord[] calldata attestations) external view override returns (bool) {
        return returnVal;
    }
}
