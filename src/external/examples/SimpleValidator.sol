// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ISchemaValidator.sol";
import { AttestationRecord } from "../../DataTypes.sol";

contract SimpleValidator is ISchemaValidator {
    function validateSchema(AttestationRecord calldata attestation)
        external
        pure
        override
        returns (bool)
    {
        return true;
    }
}
