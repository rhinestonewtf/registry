// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRecord, PackedModuleTypes, ModuleType } from "../DataTypes.sol";
import { ZERO_TIMESTAMP, ZERO_MODULE_TYPE } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";

/**
 * Library implements checks to validate if a storage reference for an `AttestationRecord` is currently valid
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
library TrustLib {
    using ModuleTypeLib for PackedModuleTypes;

    /**
     * Check that attestationRecord is valid:
     *                 - not revoked
     *                 - not expired
     *                 - correct module type (if not ZERO_MODULE_TYPE)
     * @notice this function reverts if the attestationRecord is not valid
     * @param expectedType the expected module type. if this is ZERO_MODULE_TYPE, types specified in the attestation are ignored
     * @param $attestation the storage reference of the attestation record to check
     */
    function enforceValid(AttestationRecord storage $attestation, ModuleType expectedType) internal view {
        uint256 attestedAt;
        uint256 expirationTime;
        uint256 revocationTime;
        PackedModuleTypes packedModuleType;

        /*
         * Ensure only one SLOAD
         * Assembly equiv to:
         *
         *     uint256 attestedAt = record.time;
         *     uint256 expirationTime = record.expirationTime;
         *     uint256 revocationTime = record.revocationTime;
         *     PackedModuleTypes packedModuleType = record.moduleTypes;
         */
        assembly {
            let mask := 0xFFFFFFFF
            let slot := sload($attestation.slot)
            attestedAt := and(mask, slot)
            slot := shr(48, slot)
            expirationTime := and(mask, slot)
            slot := shr(48, slot)
            revocationTime := and(mask, slot)
            slot := shr(48, slot)
            packedModuleType := and(mask, slot)
        }

        // check if any attestation was made
        if (attestedAt == ZERO_TIMESTAMP) {
            revert IRegistry.AttestationNotFound();
        }

        // check if attestation has expired
        if (expirationTime != ZERO_TIMESTAMP && block.timestamp > expirationTime) {
            revert IRegistry.AttestationNotFound();
        }

        // check if attestation has been revoked
        if (revocationTime != ZERO_TIMESTAMP) {
            revert IRegistry.RevokedAttestation($attestation.attester);
        }

        // if a expectedType is set, check if the attestation is for the correct module type
        // if no expectedType is set, module type is not checked
        if (expectedType != ZERO_MODULE_TYPE && !packedModuleType.isType(expectedType)) {
            revert IRegistry.InvalidModuleType();
        }
    }

    /**
     * Check that attestationRecord is valid:
     *                 - not revoked
     *                 - not expired
     *                 - correct module type (if not ZERO_MODULE_TYPE)
     * @dev this function DOES NOT revert if the attestationRecord is not valid, but returns false
     * @param expectedType the expected module type. if this is ZERO_MODULE_TYPE, types specified in the attestation are ignored
     * @param $attestation the storage reference of the attestation record to check
     */
    function checkValid(AttestationRecord storage $attestation, ModuleType expectedType) internal view returns (bool) {
        uint256 attestedAt;
        uint256 expirationTime;
        uint256 revocationTime;
        PackedModuleTypes packedModuleType;

        /*
         * Ensure only one SLOAD
         * Assembly equiv to:
         *
         *     uint256 attestedAt = record.time;
         *     uint256 expirationTime = record.expirationTime;
         *     uint256 revocationTime = record.revocationTime;
         *     PackedModuleTypes packedModuleType = record.moduleTypes;
         */
        assembly {
            let mask := 0xFFFFFFFF
            let slot := sload($attestation.slot)
            attestedAt := and(mask, slot)
            slot := shr(48, slot)
            expirationTime := and(mask, slot)
            slot := shr(48, slot)
            revocationTime := and(mask, slot)
            slot := shr(48, slot)
            packedModuleType := and(mask, slot)
        }

        // check if any attestation was made
        if (attestedAt == ZERO_TIMESTAMP) {
            return false;
        }

        // check if attestation has expired
        if (expirationTime != ZERO_TIMESTAMP && block.timestamp > expirationTime) {
            return false;
        }

        // check if attestation has been revoked
        if (revocationTime != ZERO_TIMESTAMP) {
            return false;
        }
        // if a expectedType is set, check if the attestation is for the correct module type
        // if no expectedType is set, module type is not checked
        if (expectedType != ZERO_MODULE_TYPE && !packedModuleType.isType(expectedType)) {
            return false;
        }
        return true;
    }
}
