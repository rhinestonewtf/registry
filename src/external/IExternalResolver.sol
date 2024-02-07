// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord, ModuleRecord } from "../DataTypes.sol";
import { IERC165 } from "forge-std/interfaces/IERC165.sol";

/**
 * @title The interface of an optional schema resolver.
 * @dev The resolver is responsible for validating the schema and attestation data.
 * @dev The resolver is also responsible for processing the attestation and revocation requests.
 *
 */
interface IExternalResolver is IERC165 {
    /**
     * @dev Processes an attestation and verifies whether it's valid.
     *
     * @param attestation The new attestation.
     *
     * @return Whether the attestation is valid.
     */
    function resolveAttestation(AttestationRecord calldata attestation)
        external
        payable
        returns (bool);

    function resolveAttestation(AttestationRecord[] calldata attestation)
        external
        payable
        returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     *
     * @return Whether the attestation can be revoked.
     */
    function resolveRevocation(AttestationRecord calldata attestation)
        external
        payable
        returns (bool);
    function resolveRevocation(AttestationRecord[] calldata attestation)
        external
        payable
        returns (bool);

    /**
     * @dev Processes a Module Registration
     *
     * @param module Module registration artefact
     *
     * @return Whether the registration is valid
     */
    function resolveModuleRegistration(ModuleRecord calldata module)
        external
        payable
        returns (bool);
}
