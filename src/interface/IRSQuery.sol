// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { Attestation } from "../Common.sol";
/**
 * RSQuery interface allows for the verification of attestations
 * with potential for reversion in case of invalid attestation.
 *
 * @author zeroknots
 */

interface IRSQuery {
    error RevokedAttestation(bytes32 attestationId);
    /**
     * Verify an attestation associated with a given module and authority. Revert if the attestation is invalid.
     *
     * @param plugin The address of the module to verify
     * @param trustedEntity The address of the authority issuing the attestation
     * @return listedAt True if the attestation is valid
     * @return revokedAt True if the attestation is valid
     */

    function check(
        address plugin,
        address trustedEntity
    )
        external
        view
        returns (uint48 listedAt, uint48 revokedAt);

    /**
     * Verify a set of attestations associated with a given module and a list of authorities. Revert if any attestation is invalid.
     *
     * @param module The address of the module to verify
     * @param authorities The list of authorities issuing the attestations
     * @param threshold The minimum number of valid attestations required
     * @return verified True if the number of valid attestations is at least the threshold
     */
    function check(
        address module,
        address[] memory authorities,
        uint256 threshold
    )
        external
        view
        returns (bool verified);

    /**
     * Verify an attestation using its id. Revert if the attestation is invalid.
     *
     * @param attestationId The id of the attestation to verify
     * @return verified True if the attestation is valid
     */
    function verifyWithRevert(bytes32 attestationId) external view returns (bool verified);

    /**
     * Verify a set of attestations using their ids. Revert if any attestation is invalid.
     *
     * @param attestationIds The ids of the attestations to verify
     * @param threshold The minimum number of valid attestations required
     * @return verified True if the number of valid attestations is at least the threshold
     */
    function verifyWithRevert(
        bytes32[] memory attestationIds,
        uint256 threshold
    )
        external
        view
        returns (bool verified);

    /**
     * Find an attestation associated with a given module and authority.
     *
     * @param module The address of the module
     * @param authority The address of the authority issuing the attestation
     * @return attestation The attestation associated with the module and authority
     */
    function findAttestation(
        address module,
        address authority
    )
        external
        view
        returns (Attestation memory attestation);

    /**
     * Find an attestations associated with a given module and authority.
     *
     * @param module The address of the module
     * @param authority The address of the authority issuing the attestation
     * @return attestations The attestations associated with the module and authority
     */
    function findAttestation(
        address module,
        address[] memory authority
    )
        external
        view
        returns (Attestation[] memory attestations);
}
