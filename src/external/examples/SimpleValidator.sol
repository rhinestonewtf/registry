// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISchemaValidator } from "../ISchemaValidator.sol";
import { AttestationRequestData } from "../../DataTypes.sol";

/**
 * @title SimpleValidator
 * @author zeroknots
 * @notice A simple validator that always returns true.
 */
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

    function supportsInterface(bytes4 interfaceID) external view override returns (bool) { }
}
