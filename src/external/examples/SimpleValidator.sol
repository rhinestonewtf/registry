// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../ISchemaValidator.sol";
import { AttestationRequestData } from "../../DataTypes.sol";

contract SimpleValidator is ISchemaValidator {
    function validateSchema(AttestationRequestData calldata attestation)
        external
        pure
        override
        returns (bool)
    {
        return true;
    }

    function validateSchema(AttestationRequestData[] calldata attestation)
        external
        pure
        override
        returns (bool)
    {
        return true;
    }
}
