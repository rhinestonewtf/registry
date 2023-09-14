// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AttestationRecord, ModuleRecord } from "../Common.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaValidator {
    function validateSchema(AttestationRecord calldata attestation) external view returns (bool);
}
