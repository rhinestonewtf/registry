// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    AccessDenied, NotFound, NO_EXPIRATION_TIME, InvalidLength, uncheckedInc
} from "./Common.sol";
import "./RSAttestation.sol";

/// @title RSRegistry
/// @author zeroknots
/// @notice The global attestation registry.
abstract contract RSQuery {
    error RevokedAttestation(bytes32 attestationId);

    function verifyWithRevert(
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
            address authority = authorities[i];
            bytes32 uid = _getAttestation(module, authority);
            if (threshold == 0) return true;
            if (uid != EMPTY_UID) {
                _verifyAttestation(uid);
                --threshold;
            }
        }
        return false;
    }

    function verifyWithRevert(
        address module,
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
            _verifyAttestation(attestationIds[i]);
            --threshold;
        }
        return false;
    }

    function _verifyAttestation(bytes32 attestationId) internal view {
        Attestation storage attestation = _getAttestation(attestationId);
        bytes32 refUID = attestation.refUID;
        if (attestation.revocationTime != 0) revert RevokedAttestation(attestationId);
        if (refUID != EMPTY_UID) _verifyAttestation(refUID); // @TODO security issue?
    }

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
