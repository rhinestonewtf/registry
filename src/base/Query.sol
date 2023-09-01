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
        bytes32 uid = _getAttestation(module, authority);
        AttestationRecord storage attestation = _getAttestation(uid);

        listedAt = attestation.expirationTime < block.timestamp ? attestation.time : 0;
        revokedAt = attestation.revocationTime;
        if (listedAt == 0) revert AttestationNotFound();
        if (revokedAt != 0) revert RevokedAttestation(uid);
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

        for (uint256 i; i < authoritiesLength; uncheckedInc(i)) {
            if (threshold == 0) return;
            (uint256 listedAt, uint256 revokedAt) = check(module, authorities[i]);
            if (revokedAt != 0) revert RevokedAttestation("tbd");
            if (listedAt == NO_EXPIRATION_TIME) continue;
            --threshold;
        }
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

        for (uint256 i; i < authoritiesLength; uncheckedInc(i)) {
            if (threshold == 0) return;
            (uint256 listedAt, uint256 revokedAt) = check(module, authorities[i]);
            if (revokedAt != 0) continue;
            if (listedAt == NO_EXPIRATION_TIME) continue;
            --threshold;
        }
        revert InsufficientAttestations();
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
        uint256 length = authorities.length;
        attestations = new AttestationRecord[](length);
        for (uint256 i; i < length; uncheckedInc(i)) {
            attestations[i] = findAttestation(module, authorities[i]);
        }
    }

    function _verifyAttestation(bytes32 attestationId) internal view {
        AttestationRecord storage attestation = _getAttestation(attestationId);
        bytes32 refUID = attestation.refUID;
        if (attestation.revocationTime != 0) {
            revert RevokedAttestation(attestationId);
        }
        if (attestation.time != 0) revert Attestation.InvalidAttestation();
        if (refUID != EMPTY_UID) _verifyAttestation(refUID); // @TODO security issue?
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
