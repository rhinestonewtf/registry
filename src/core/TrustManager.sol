// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    AttestationRecord,
    PackedModuleTypes,
    ModuleType,
    TrustedAttesterRecord
} from "../DataTypes.sol";
import { ZERO_TIMESTAMP, ZERO_MODULE_TYPE, ZERO_ADDRESS } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";
import { TrustManagerExternalAttesterList } from "./TrustManagerExternalAttesterList.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";
import { LibSort } from "solady/utils/LibSort.sol";

/**
 * @title TrustManager
 * Allows smart accounts to query the registry for the security status of modules.
 * Smart accounts may trust a list of attesters to attest to the security status of
 *   modules and configure a minimum threshold of how many attestations have to be in place
 *   to consider a module as "trust worthy"
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 * Implements EIP-7484 to query attestations stored in the registry.
 * @dev This contract is abstract and provides utility functions to query attestations.
 */
abstract contract TrustManager is IRegistry, TrustManagerExternalAttesterList {
    using ModuleTypeLib for PackedModuleTypes;
    using LibSort for address[];

    mapping(address account => TrustedAttesterRecord attesters) internal _accountToAttester;

    // Deliberately using memory here, so we can sort the array
    function trustAttesters(uint8 threshold, address[] memory attesters) external {
        uint256 attestersLength = attesters.length;
        attesters.sort();
        attesters.uniquifySorted();
        if (attestersLength == 0) revert InvalidTrustedAttesterInput();
        if (attesters.length != attestersLength) revert InvalidTrustedAttesterInput();
        // sort attesters

        TrustedAttesterRecord storage _att = _accountToAttester[msg.sender];
        // threshold cannot be greater than the number of attesters
        if (threshold > attestersLength) {
            threshold = uint8(attestersLength);
        }
        //
        _att.attesterCount = uint8(attestersLength);
        _att.threshold = threshold;
        _att.attester = attesters[0];

        attestersLength--;
        for (uint256 i; i < attestersLength; i++) {
            address _attester = attesters[i];
            // user could have set attester to address(0)
            if (_attester == ZERO_ADDRESS) revert InvalidTrustedAttesterInput();
            _att.linkedAttesters[_attester] = attesters[i + 1];
        }
        emit NewTrustedAttesters();
    }

    function check(address module) external view {
        _check(msg.sender, module, ZERO_MODULE_TYPE);
    }

    function checkForAccount(address smartAccount, address module) external view {
        _check(smartAccount, module, ZERO_MODULE_TYPE);
    }

    function check(address module, ModuleType moduleType) external view {
        _check(msg.sender, module, moduleType);
    }

    function checkForAccount(
        address smartAccount,
        address module,
        ModuleType moduleType
    )
        external
        view
    {
        _check(smartAccount, module, moduleType);
    }

    function _check(address smartAccount, address module, ModuleType moduleType) internal view {
        TrustedAttesterRecord storage trustedAttesters = _accountToAttester[smartAccount];
        // SLOAD from one slot
        uint256 attesterCount = trustedAttesters.attesterCount;
        uint256 threshold = trustedAttesters.threshold;
        address attester = trustedAttesters.attester;

        // smart account has no trusted attesters set
        if (attester == ZERO_ADDRESS && threshold != 0) {
            revert NoTrustedAttestersFound();
        }
        // smart account only has ONE trusted attester
        // use this condition to save gas
        else if (threshold == 1) {
            AttestationRecord storage record =
                _getAttestation({ module: module, attester: attester });
            _requireValidAttestation(moduleType, record);
        }
        // smart account has more than one trusted attester
        else {
            // loop though list and check if the attestation is valid
            AttestationRecord storage record =
                _getAttestation({ module: module, attester: attester });
            _requireValidAttestation(moduleType, record);
            for (uint256 i = 1; i < attesterCount; i++) {
                threshold--;
                // get next attester from linked List
                attester = trustedAttesters.linkedAttesters[attester];
                record = _getAttestation({ module: module, attester: attester });
                _requireValidAttestation(moduleType, record);
                // if threshold reached, exit loop
                if (threshold == 0) return;
            }
        }
    }

    /**
     * Check that attestationRecord is valid:
     *                 - not revoked
     *                 - not expired
     *                 - correct module type (if not ZERO_MODULE_TYPE)
     */
    function _requireValidAttestation(
        ModuleType expectedType,
        AttestationRecord storage record
    )
        internal
        view
    {
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

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let mask := 0xffffffffffff
            let slot := sload(record.slot)
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
            revert AttestationNotFound();
        }

        // check if attestation has expired
        if (expirationTime != ZERO_TIMESTAMP && block.timestamp > expirationTime) {
            revert AttestationNotFound();
        }

        // check if attestation has been revoked
        if (revocationTime != ZERO_TIMESTAMP) {
            revert RevokedAttestation(record.attester);
        }
        // if a expectedType is set, check if the attestation is for the correct module type
        // if no expectedType is set, module type is not checked
        if (expectedType != ZERO_MODULE_TYPE && !packedModuleType.isType(expectedType)) {
            revert InvalidModuleType();
        }
    }

    function getTrustedAttesters(address smartAccount)
        public
        view
        returns (address[] memory attesters)
    {
        TrustedAttesterRecord storage trustedAttesters = _accountToAttester[smartAccount];
        uint256 count = trustedAttesters.attesterCount;
        address attester0 = trustedAttesters.attester;
        attesters = new address[](count);
        attesters[0] = attester0;

        for (uint256 i = 1; i < count; i++) {
            // get next attester from linked List
            attesters[i] = trustedAttesters.linkedAttesters[attesters[i - 1]];
        }
    }
}
