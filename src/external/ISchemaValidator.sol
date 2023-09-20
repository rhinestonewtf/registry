// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AttestationRequestData, ModuleRecord } from "../DataTypes.sol";
import { IERC165 } from "forge-std/interfaces/IERC165.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaValidator is IERC165 {
    function validateSchema(AttestationRequestData calldata attestation)
        external
        view
        returns (bool);
    function validateSchema(AttestationRequestData[] calldata attestations)
        external
        view
        returns (bool);
}
