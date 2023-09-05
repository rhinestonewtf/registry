// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    AccessDenied, NotFound, NO_EXPIRATION_TIME, InvalidLength, uncheckedInc
} from "../Common.sol";
import "../interface/IQuery.sol";
import "./Attestation.sol";

import "forge-std/console2.sol";

/// @title RSRegistry
/// @author zeroknots
/// @notice The global attestation registry.
abstract contract Query is IQuery {
    /**
     * @inheritdoc IQuery
     */
    function check(
        address module,
        address authority
    )
        public
        view
        returns (uint48 listedAt, uint48 revokedAt)
    {
        AttestationRecord storage attestation = _findAttestation(module, authority);

        uint48 expirationTime = attestation.expirationTime;
        listedAt = expirationTime != 0 && expirationTime < block.timestamp ? 0 : attestation.time;
        if (listedAt == 0) revert AttestationNotFound();

        revokedAt = attestation.revocationTime;
        if (revokedAt != 0) revert RevokedAttestation(attestation.uid);
    }

    /**
     * @inheritdoc IQuery
     */
    function verify(
        address module,
        address[] calldata authorities,
        uint256 threshold
    )
        external
        view
    {
        uint256 authoritiesLength = authorities.length;
        if (authoritiesLength < threshold || threshold == 0) {
            threshold = authoritiesLength;
        }

        uint256 timeNow = block.timestamp;

        for (uint256 i; i < authoritiesLength; i = uncheckedInc(i)) {
            AttestationRecord storage attestation = _findAttestation(module, authorities[i]);

            if (attestation.revocationTime != 0) {
                revert RevokedAttestation(attestation.uid);
            }

            uint48 expirationTime = attestation.expirationTime;
            if (expirationTime != 0 && expirationTime < timeNow) {
                revert AttestationNotFound();
            }

            if (attestation.time == 0) continue;

            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return;
        revert InsufficientAttestations();
    }

    /**
     * @inheritdoc IQuery
     */
    function verifyUnsafe(
        address module,
        address[] calldata authorities,
        uint256 threshold
    )
        external
        view
    {
        uint256 authoritiesLength = authorities.length;
        if (authoritiesLength < threshold || threshold == 0) {
            threshold = authoritiesLength;
        }

        uint256 timeNow = block.timestamp;

        for (uint256 i; i < authoritiesLength; i = uncheckedInc(i)) {
            if (threshold == 0) return;
            AttestationRecord storage attestation = _findAttestation(module, authorities[i]);

            if (attestation.revocationTime != 0) continue;

            uint48 expirationTime = attestation.expirationTime;
            uint48 listedAt = expirationTime != 0 && expirationTime < timeNow ? 0 : attestation.time;
            if (listedAt == 0) continue;

            --threshold;
        }
        revert InsufficientAttestations();
    }

    function _findAttestation(
        address module,
        address authority
    )
        internal
        view
        returns (AttestationRecord storage attestation)
    {
        bytes32 attestionId = _getAttestation(module, authority);
        attestation = _getAttestation(attestionId);
    }

    /**
     * @inheritdoc IQuery
     */
    function findAttestation(
        address module,
        address authority
    )
        public
        view
        returns (AttestationRecord memory attestation)
    {
        bytes32 attestionId = _getAttestation(module, authority);
        attestation = _getAttestation(attestionId);
    }

    /**
     * @inheritdoc IQuery
     */
    function findAttestation(
        address module,
        address[] memory authorities
    )
        external
        view
        returns (AttestationRecord[] memory attestations)
    {
        uint256 authoritiesLength = authorities.length;
        attestations = new AttestationRecord[](authoritiesLength);
        for (uint256 i; i < authoritiesLength; i = uncheckedInc(i)) {
            attestations[i] = findAttestation(module, authorities[i]);
        }
    }

    function _getAttestation(
        address module,
        address authority
    )
        internal
        view
        virtual
        returns (bytes32);

    function _getAttestation(bytes32 attestationId)
        internal
        view
        virtual
        returns (AttestationRecord storage);
}
