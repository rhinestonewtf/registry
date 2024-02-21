// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRecord, PackedModuleTypes, ModuleType, TrustedAttesterRecord } from "../DataTypes.sol";
import { ZERO_MODULE_TYPE, ZERO_ADDRESS } from "../Common.sol";
// solhint-disable-next-line no-unused-import
import { IRegistry, IERC7484 } from "../IRegistry.sol";
import { ModuleTypeLib } from "../lib/ModuleTypeLib.sol";
import { TrustLib } from "../lib/TrustLib.sol";
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
abstract contract TrustManager is IRegistry {
    using ModuleTypeLib for PackedModuleTypes;
    using TrustLib for AttestationRecord;
    using LibSort for address[];

    mapping(address account => TrustedAttesterRecord attesters) internal $accountToAttester;

    /**
     * @inheritdoc IRegistry
     */
    function trustAttesters(
        uint8 threshold,
        address[] memory attesters // deliberately using memory to allow sorting and uniquifying
    )
        external
    {
        uint256 attestersLength = attesters.length;
        // sort attesters and remove duplicates
        attesters.sort();
        attesters.uniquifySorted();
        // if attesters array has duplicates, revert
        if (attestersLength == 0) revert InvalidTrustedAttesterInput();
        if (attesters.length != attestersLength) revert InvalidTrustedAttesterInput();

        TrustedAttesterRecord storage $trustedAttester = $accountToAttester[msg.sender];
        // threshold cannot be greater than the number of attesters
        if (threshold > attestersLength) {
            threshold = uint8(attestersLength);
        }
        $trustedAttester.attesterCount = uint8(attestersLength);
        $trustedAttester.threshold = threshold;
        $trustedAttester.attester = attesters[0];

        attestersLength--;
        // setup the linked list of trusted attesters
        for (uint256 i; i < attestersLength; i++) {
            address _attester = attesters[i];
            // user could have set attester to address(0)
            if (_attester == ZERO_ADDRESS) revert InvalidTrustedAttesterInput();
            $trustedAttester.linkedAttesters[_attester] = attesters[i + 1];
        }
        emit NewTrustedAttesters();
    }

    /**
     * @inheritdoc IERC7484
     */
    function check(address module) external view {
        _check(msg.sender, module, ZERO_MODULE_TYPE);
    }

    /**
     * @inheritdoc IERC7484
     */
    function checkForAccount(address smartAccount, address module) external view {
        _check(smartAccount, module, ZERO_MODULE_TYPE);
    }

    /**
     * @inheritdoc IERC7484
     */
    function check(address module, ModuleType moduleType) external view {
        _check(msg.sender, module, moduleType);
    }

    /**
     * @inheritdoc IERC7484
     */
    function checkForAccount(address smartAccount, address module, ModuleType moduleType) external view {
        _check(smartAccount, module, moduleType);
    }

    /**
     * Internal helper function to check for module's security attestations on behalf of a SmartAccount
     * will use registy's storage to get the trusted attester(s) of a smart account, and check if the module was attested
     * @param smartAccount the smart account to check for
     * @param module address of the module to check
     * @param moduleType (optional param), setting  moduleType = 0, will ignore moduleTypes in attestations
     */
    function _check(address smartAccount, address module, ModuleType moduleType) internal view {
        TrustedAttesterRecord storage $trustedAttesters = $accountToAttester[smartAccount];
        // SLOAD from one slot
        uint256 attesterCount = $trustedAttesters.attesterCount;
        uint256 threshold = $trustedAttesters.threshold;
        address attester = $trustedAttesters.attester;

        // smart account has no trusted attesters set
        if (attester == ZERO_ADDRESS || threshold == 0) {
            revert NoTrustedAttestersFound();
        }
        // smart account only has ONE trusted attester
        // use this condition to save gas
        else if (threshold == 1) {
            AttestationRecord storage $attestation = $getAttestation({ module: module, attester: attester });
            $attestation.enforceValid(moduleType);
        }
        // smart account has more than one trusted attester
        else {
            // loop though list and check if the attestation is valid
            AttestationRecord storage $attestation = $getAttestation({ module: module, attester: attester });
            if ($attestation.checkValid(moduleType)) threshold--;
            for (uint256 i = 1; i < attesterCount; i++) {
                // get next attester from linked List
                attester = $trustedAttesters.linkedAttesters[attester];
                $attestation = $getAttestation({ module: module, attester: attester });
                if ($attestation.checkValid(moduleType)) threshold--;
                // if threshold reached, exit loop
                if (threshold == 0) return;
            }
            if (threshold > 0) revert InsufficientAttestations();
        }
    }

    /**
     * @inheritdoc IRegistry
     */
    function findTrustedAttesters(address smartAccount) public view returns (address[] memory attesters) {
        TrustedAttesterRecord storage $trustedAttesters = $accountToAttester[smartAccount];
        uint256 count = $trustedAttesters.attesterCount;
        address attester0 = $trustedAttesters.attester;
        attesters = new address[](count);
        attesters[0] = attester0;

        for (uint256 i = 1; i < count; i++) {
            // get next attester from linked List
            attesters[i] = $trustedAttesters.linkedAttesters[attesters[i - 1]];
        }
    }

    function $getAttestation(address module, address attester) internal view virtual returns (AttestationRecord storage $attestation);
}
