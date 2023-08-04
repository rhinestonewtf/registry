// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    AccessDenied, NotFound, NO_EXPIRATION_TIME, InvalidLength, uncheckedInc
} from "../Common.sol";
import "../interface/IRSQuery.sol";
import "./RSAttestation.sol";

import "forge-std/console2.sol";

/// @title RSRegistry
/// @author zeroknots
/// @notice The global attestation registry.
abstract contract RSQuery is IRSQuery {
    /**
     * @inheritdoc IRSQuery
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
        Attestation storage attestation = _getAttestation(uid);

        listedAt = attestation.time;
        revokedAt = attestation.revocationTime;
    }

    /**
     * @inheritdoc IRSQuery
     */
    function verify(
        address module,
        address[] memory authorities,
        uint256 threshold
    )
        external
        view
        returns (bool verified)
    {
        uint256 length = authorities.length;
        if (length < threshold || threshold == 0) threshold = length;

        for (uint256 i; i < length; uncheckedInc(i)) {
            if (threshold == 0) return true;
            (uint256 listedAt, uint256 revokedAt) = check(module, authorities[i]);
            if (revokedAt == 0) return false;
            if (listedAt == NO_EXPIRATION_TIME) continue;
            --threshold;
        }
        return false;
    }

    /**
     * @inheritdoc IRSQuery
     */
    function verifyWithRevert(bytes32 attestationId) public view returns (bool verified) {
        _verifyAttestation(attestationId);
        verified = true;
    }

    /**
     * @inheritdoc IRSQuery
     */
    function verifyWithRevert(
        bytes32[] memory attestationIds,
        uint256 threshold
    )
        external
        view
        returns (bool verified)
    {
        uint256 length = attestationIds.length;
        if (length < threshold || threshold == 0) threshold = length;

        for (uint256 i; i < length; uncheckedInc(i)) {
            if (threshold == 0) return true;
            verifyWithRevert(attestationIds[i]);
            --threshold;
        }
        return false;
    }

    /**
     * @inheritdoc IRSQuery
     */
    function findAttestation(
        address module,
        address authority
    )
        public
        view
        returns (Attestation memory attestation)
    {
        bytes32 attestionId = _getAttestation(module, authority);
        attestation = _getAttestation(attestionId);
    }

    /**
     * @inheritdoc IRSQuery
     */
    function findAttestation(
        address module,
        address[] memory authority
    )
        external
        view
        returns (Attestation[] memory attestations)
    {
        uint256 length = authority.length;
        attestations = new Attestation[](length);
        for (uint256 i; i < length; uncheckedInc(i)) {
            attestations[i] = findAttestation(module, authority[i]);
        }
    }

    function _verifyAttestation(bytes32 attestationId) internal view {
        Attestation storage attestation = _getAttestation(attestationId);
        bytes32 refUID = attestation.refUID;
        if (attestation.revocationTime != 0) revert RevokedAttestation(attestationId);
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
        returns (Attestation storage);
}
