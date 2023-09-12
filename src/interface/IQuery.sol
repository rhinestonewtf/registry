// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord } from "../Common.sol";

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
     * Verify an attestation associated with a given module and authority.
     *
     * @param plugin The address of the module to verify
     * @param trustedEntity The address of the authority issuing the attestation
     * @return listedAt timestamp  Not zero if the attesation is valid
     * @return revokedAt timestamp not zero if the attestation was revoked.
     */

    function check(
        address plugin,
        address trustedEntity
    )
        external
        view
        returns (uint48 listedAt, uint48 revokedAt);

    /**
     * Verify a set of attestations associated with a given module and a list of authorities.
     * @dev Will revert if threshold is not met.
     * @dev Will revert if any of the attestations have been revoked (even if threshold is met)!
     *
     * @param module The address of the module to verify
     * @param authorities The list of authorities issuing the attestations
     * @param threshold The minimum number of valid attestations required
     */
    function verify(
        address module,
        address[] memory authorities,
        uint256 threshold
    )
        external
        view;

    /**
     * Verify a set of attestations associated with a given module and a list of authorities.
     * @dev Will revert if threshold is not met.
     * @dev Will NOT revert if any of the attestations have been revoked.
     *
     * @param module The address of the module to verify
     * @param authorities The list of authorities issuing the attestations
     * @param threshold The minimum number of valid attestations required
     */
    function verifyUnsafe(
        address module,
        address[] memory authorities,
        uint256 threshold
    )
        external
        view;

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
        returns (AttestationRecord memory attestation);

    /**
     * Find an attestations associated with a given module and authority.
     *
     * @param module The address of the module
     * @param authority The address of the authority issuing the attestation
     * @return attestations The attestations associated with the module and authority
     */
    function findAttestations(
        address module,
        address[] memory authority
    )
        external
        view
        returns (AttestationRecord[] memory attestations);
}
