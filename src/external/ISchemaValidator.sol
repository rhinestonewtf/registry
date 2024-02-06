// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRequestData } from "../DataTypes.sol";
import { IERC165 } from "forge-std/interfaces/IERC165.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaValidator is IERC165 {
    /**
     * @notice Validates an attestation request.
     */
    function validateSchema(AttestationRequestData calldata attestation)
        external
        view
        returns (bool);

    /**
     * @notice Validates an array of attestation requests.
     */
    function validateSchema(AttestationRequestData[] calldata attestations)
        external
        view
        returns (bool);
}
