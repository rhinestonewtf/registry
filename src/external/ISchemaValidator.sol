// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AttestationRequestData, ModuleRecord } from "../DataTypes.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaValidator {
    function validateSchema(AttestationRequestData calldata attestation)
        external
        view
        returns (bool);
    function validateSchema(AttestationRequestData[] calldata attestations)
        external
        view
        returns (bool);
}
