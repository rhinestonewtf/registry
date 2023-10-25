// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * ERC-7484 compliant interface for the registry.
 *
 * @author zeroknots
 */
interface IERC7484 {
    /**
     * @notice Queries the attestation of a specific attester for a given module.
     *
     * @dev If an attestation is not found, expired or is revoked, the function will revert.
     *
     * @param module The address of the module being queried.
     * @param attester The address of the attester attestation is being queried.
     *
     * @return attestedAt The time the attestation was listed. Returns 0 if not listed or expired.
     */
    function check(address module, address attester) external view returns (uint256 attestedAt);

    /**
     * @notice Verifies the validity of attestations for a given module against a threshold.
     *
     * @dev This function will revert if the threshold is not met.
     * @dev Will also revert if any of the attestations have been revoked (even if threshold is met).
     *
     * @param module The address of the module being verified.
     * @param attesters The list of attesters whose attestations are being verified.
     * @param threshold The minimum number of valid attestations required.
     *
     * @return attestedAtArray The list of attestation times associated with the given module and attesters.
     */
    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray);
}
