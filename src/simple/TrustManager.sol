// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRecord, PackedModuleTypes, ModuleType } from "../DataTypes.sol";
import { ZERO_TIMESTAMP } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";

/**
 * @title TrustManager
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 * Implements EIP-7484 to query attestations stored in the registry.
 * @dev This contract is abstract and provides utility functions to query attestations.
 */
abstract contract TrustManager is IRegistry {
    using ModuleTypeLib for PackedModuleTypes;

    event NewAttesters();
    // packed struct to allow for efficient storage.
    // if only one attester is trusted, it only requires 1 SLOAD

    struct TrustedAttesters {
        uint8 attesterCount;
        uint8 threshold;
        address attester;
        mapping(address attester => address linkedAttester) linkedAttesters;
    }

    mapping(address account => TrustedAttesters attesters) internal _accountToAttester;

    function setAttester(uint8 threshold, address[] calldata attesters) external {
        uint256 attestersLength = attesters.length;
        if (attestersLength == 0) revert();
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
            _att.linkedAttesters[attesters[i]] = attesters[i + 1];
        }
    }

    function check(address module) external view { }

    function checkForAccount(address smartAccount, address module) external view { }

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
            revert NoAttestersFound();
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
            threshold--;
            for (uint256 i = 1; i < attesterCount; i++) {
                // get next attester from linked List
                attester = trustedAttesters.linkedAttesters[attester];
                record = _getAttestation({ module: module, attester: attester });
                _requireValidAttestation(moduleType, record);
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

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage attestation);
}
