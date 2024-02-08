// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord } from "../DataTypes.sol";
import { ZERO_TIMESTAMP } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

abstract contract TrustManagerExternalAttesterList is IRegistry {
    function check(address module, address attester) public view returns (uint256 attestedAt) {
        AttestationRecord storage attestation = _getAttestation(module, attester);

        // attestedAt = attestation.time;
        uint256 expirationTime; // = attestation.expirationTime;
        uint256 revocationTime; // = attestation.revocationTime;

        // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
        // @dev the solidity version of the assembly code is above
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let mask := 0xffffffffffff
            let times := sload(attestation.slot)
            attestedAt := and(mask, times)
            times := shr(48, times)
            expirationTime := and(mask, times)
            times := shr(48, times)
            revocationTime := and(mask, times)
        }

        if (attestedAt == ZERO_TIMESTAMP) {
            revert AttestationNotFound();
        }

        if (expirationTime != ZERO_TIMESTAMP) {
            if (block.timestamp > expirationTime) {
                revert AttestationNotFound();
            }
        }

        if (revocationTime != ZERO_TIMESTAMP) {
            revert RevokedAttestation(attestation.attester);
        }
    }

    function checkN(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;
        attestedAtArray = new uint256[](attestersLength);

        for (uint256 i; i < attestersLength; ++i) {
            AttestationRecord storage attestation = _getAttestation(module, attesters[i]);

            uint256 attestationTime; // = attestation.time;
            uint256 expirationTime; // = attestation.expirationTime;
            uint256 revocationTime; // = attestation.revocationTime;

            // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
            // @dev the solidity version of the assembly code is above
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let mask := 0xffffffffffff
                let times := sload(attestation.slot)
                attestationTime := and(mask, times)
                times := shr(48, times)
                expirationTime := and(mask, times)
                times := shr(48, times)
                revocationTime := and(mask, times)
            }

            if (revocationTime != ZERO_TIMESTAMP) {
                revert RevokedAttestation(attestation.attester);
            }

            if (expirationTime != ZERO_TIMESTAMP) {
                if (timeNow > expirationTime) {
                    revert AttestationNotFound();
                }
            }

            attestedAtArray[i] = attestationTime;

            if (attestationTime == ZERO_TIMESTAMP) continue;
            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return attestedAtArray;
        revert InsufficientAttestations();
    }

    function checkNUnsafe(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;
        attestedAtArray = new uint256[](attestersLength);

        for (uint256 i; i < attestersLength; ++i) {
            AttestationRecord storage attestation = _getAttestation(module, attesters[i]);

            uint256 attestationTime; // = attestation.time;
            uint256 expirationTime; // = attestation.expirationTime;
            uint256 revocationTime; // = attestation.revocationTime;

            // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
            // @dev the solidity version of the assembly code is above
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let mask := 0xffffffffffff
                let times := sload(attestation.slot)
                attestationTime := and(mask, times)
                times := shr(48, times)
                expirationTime := and(mask, times)
                times := shr(48, times)
                revocationTime := and(mask, times)
            }

            if (revocationTime != ZERO_TIMESTAMP) {
                attestedAtArray[i] = 0;
                continue;
            }

            attestedAtArray[i] = attestationTime;

            if (expirationTime != ZERO_TIMESTAMP) {
                if (timeNow > expirationTime) {
                    attestedAtArray[i] = 0;
                    continue;
                }
            }

            if (attestationTime == ZERO_TIMESTAMP) continue;
            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return attestedAtArray;
        revert InsufficientAttestations();
    }

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage attestation);
}
