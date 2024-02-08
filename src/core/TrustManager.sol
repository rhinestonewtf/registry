// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord, PackedModuleTypes, ModuleType } from "../DataTypes.sol";
import { ZERO_TIMESTAMP, ZERO_MODULE_TYPE } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";
import { TrustManagerExternalAttesterList } from "./TrustManagerExternalAttesterList.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";
import { LibSort } from "solady/utils/LibSort.sol";

/**
 * @title TrustManager
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 * Implements EIP-7484 to query attestations stored in the registry.
 * @dev This contract is abstract and provides utility functions to query attestations.
 */
abstract contract TrustManager is IRegistry, TrustManagerExternalAttesterList {
    using ModuleTypeLib for PackedModuleTypes;
    using LibSort for address[];

    // packed struct to allow for efficient storage.
    // if only one attester is trusted, it only requires 1 SLOAD

    struct TrustedAttesters {
        uint8 attesterCount;
        uint8 threshold;
        address attester;
        mapping(address attester => address linkedAttester) linkedAttesters;
    }

    mapping(address account => TrustedAttesters attesters) internal _accountToAttester;

    // Deliberately using memory here, so we can sort the array
    function trustAttesters(uint8 threshold, address[] memory attesters) external {
        uint256 attestersLength = attesters.length;
        attesters.sort();
        attesters.uniquifySorted();
        if (attestersLength == 0) revert InvalidTrustedAttesterInput();
        if (attesters.length != attestersLength) revert InvalidTrustedAttesterInput();
        // sort attesters

        TrustedAttesters storage _att = _accountToAttester[msg.sender];
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
            if (_attester == address(0)) revert InvalidTrustedAttesterInput();
            _att.linkedAttesters[_attester] = attesters[i + 1];
        }
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
        TrustedAttesters storage trustedAttesters = _accountToAttester[smartAccount];
        // SLOAD from one slot
        uint256 attesterCount = trustedAttesters.attesterCount;
        uint256 threshold = trustedAttesters.threshold;
        address attester = trustedAttesters.attester;

        // smart account has no trusted attesters set
        if (attester == address(0) && threshold != 0) {
            revert NoTrustedAttestersFound();
        }
        // smart account only has ONE trusted attester
        // use this condition to save gas
        else if (threshold == 1) {
            AttestationRecord storage record =
                _getAttestation({ module: module, attester: attester });
            if (moduleType != ZERO_MODULE_TYPE) _requireValidAttestation(moduleType, record);
        }
        // smart account has more than one trusted attester
        else {
            // loop though list and check if the attestation is valid
            AttestationRecord storage record =
                _getAttestation({ module: module, attester: attester });
            if (moduleType != ZERO_MODULE_TYPE) _requireValidAttestation(moduleType, record);
            threshold--;
            for (uint256 i = 1; i < attesterCount; i++) {
                // get next attester from linked List
                attester = trustedAttesters.linkedAttesters[attester];
                record = _getAttestation({ module: module, attester: attester });
                if (moduleType != ZERO_MODULE_TYPE) _requireValidAttestation(moduleType, record);
                // if threshold reached, exit loop
                if (threshold == 0) return;
            }
        }
    }

    function _requireValidAttestation(
        ModuleType expectedType,
        AttestationRecord storage record
    )
        internal
        view
    {
        // cache values
        uint256 attestedAt = record.time;
        uint256 expirationTime = record.expirationTime;
        uint256 revocationTime = record.revocationTime;
        PackedModuleTypes packedModuleType = record.moduleTypes;

        if (attestedAt == ZERO_TIMESTAMP) {
            revert AttestationNotFound();
        }

        if (expirationTime != ZERO_TIMESTAMP && block.timestamp > expirationTime) {
            revert AttestationNotFound();
        }

        if (revocationTime != ZERO_TIMESTAMP) {
            revert RevokedAttestation(record.attester);
        }
        if (!packedModuleType.isType(expectedType)) {
            revert InvalidModuleType();
        }
    }

    function _requireValidAttestation(AttestationRecord storage record) internal view {
        // cache values
        uint256 attestedAt = record.time;
        uint256 expirationTime = record.expirationTime;
        uint256 revocationTime = record.revocationTime;

        if (attestedAt == ZERO_TIMESTAMP) {
            revert AttestationNotFound();
        }

        if (expirationTime != ZERO_TIMESTAMP && block.timestamp > expirationTime) {
            revert AttestationNotFound();
        }

        if (revocationTime != ZERO_TIMESTAMP) {
            revert RevokedAttestation(record.attester);
        }
    }

    function getTrustedAttesters() public view returns (address[] memory attesters) {
        return getTrustedAttesters(msg.sender);
    }

    function getTrustedAttesters(address smartAccount)
        public
        view
        returns (address[] memory attesters)
    {
        TrustedAttesters storage trustedAttesters = _accountToAttester[smartAccount];
        uint256 count = trustedAttesters.attesterCount;
        attesters = new address[](count);
        attesters[0] = trustedAttesters.attester;

        for (uint256 i = 1; i < count; i++) {
            // get next attester from linked List
            attesters[i] = trustedAttesters.linkedAttesters[attesters[i - 1]];
        }
    }
}
