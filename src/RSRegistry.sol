// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {
    AccessDenied, NotFound, NO_EXPIRATION_TIME, InvalidLength, uncheckedInc
} from "./Common.sol";
import "./RSAttestation.sol";

/// @title RSRegistry
/// @author zeroknots
/// @notice The global attestation registry.
contract RSRegistry is RSAttestation {
    error RevokedAttestation(bytes32 attestationId);

    constructor(
        Yaho _yaho,
        Yaru _yaru,
        address l1Registry
    )
        RSAttestation(_yaho, _yaru, l1Registry)
    { }

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
            bytes32 uid = _findAttestation(module, authority);
            if (uid != EMPTY_UID) {
                --threshold;
                if (threshold == 0) return true;

                Attestation storage attestation = _attestations[uid];
                if (attestation.revocationTime != 0) revert RevokedAttestation(uid);
            }
        }
        return false;
    }

    function _findAttestation(address module, address authority) internal view returns (bytes32) {
        return _moduleToAuthorityToAttestations[module][authority];
    }

    function findAttestation(
        address module,
        address authority
    )
        public
        view
        returns (Attestation memory)
    {
        bytes32 attestionId = _findAttestation(module, authority);
        return _attestations[attestionId];
    }
}
