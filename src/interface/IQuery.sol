// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord } from "../DataTypes.sol";

/**
 * Query interface allows for the verification of attestations
 * with potential for reversion in case of invalid attestation.
 *
 * @author zeroknots
 */

interface IQuery {
    error RevokedAttestation(address attester);
    error AttestationNotFound();
    error InsufficientAttestations();

    /**
     * @notice Queries the attestation status of a specific attester for a given module.
     *
     * @dev If an attestation is not found or is revoked, the function will revert.
     *
     * @param module The address of the module being queried.
     * @param attester The address of the attester whose status is being queried.
     * @return listedAt The time the attestation was listed. Returns 0 if not listed or expired.
     *
     * @return revokedAt The time the attestation was revoked.
     */
    function check(
        address module,
        address attester
    )
        external
        view
        returns (uint48 listedAt, uint48 revokedAt);

    /**
     * @notice Verifies the validity of attestations for a given module against a threshold.
     *
     * @dev This function will revert if the threshold is not met.
     * @dev Will also revert if any of the attestations have been revoked (even if threshold is met).
     *
     * @param module The address of the module being verified.
     * @param attesters The list of attesters whose attestations are being verified.
     * @param threshold The minimum number of valid attestations required.
     */
    function verify(address module, address[] memory attesters, uint256 threshold) external view;

    /**
     * @notice Verifies attestations for a given module against a threshold, but does not check revocation.
     *
     * @dev This function will revert if the threshold is not met.
     * @dev Does not verify against revoked attestations.
     *
     * @param module The address of the module being verified.
     * @param attesters The list of attesters whose attestations are being verified.
     * @param threshold The minimum number of valid attestations required.
     */
    function verifyUnsafe(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view;

    /**
     * @notice Retrieves the attestation record for a given module and attester.
     *
     * @param module The address of the module being queried.
     * @param attester The address of the attester whose record is being retrieved.
     *
     * @return attestation The attestation record associated with the given module and attester.
     */
    function findAttestation(
        address module,
        address attester
    )
        external
        view
        returns (AttestationRecord memory attestation);

    /**
     * Find an attestations associated with a given module and attester.
     *
     * @notice Retrieves attestation records for a given module and a list of attesters.
     *
     * @param module The address of the module being queried.
     * @param attesters The list of attesters whose records are being retrieved.
     *
     * @return attestations The list of attestation records associated with the given module and attesters.
     */
    function findAttestations(
        address module,
        address[] memory attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations);
}
