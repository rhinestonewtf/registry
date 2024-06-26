// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRecord, ModuleType } from "../DataTypes.sol";
import { ZERO_MODULE_TYPE } from "../Common.sol";
// solhint-disable-next-line no-unused-import
import { IRegistry, IERC7484 } from "../IRegistry.sol";
import { TrustManager } from "./TrustManager.sol";
import { TrustLib } from "../lib/TrustLib.sol";

/**
 * If smart accounts want to query the registry, and supply a list of trusted attesters in calldata, this component can be used
 * @dev This contract is abstract and provides utility functions to query attestations with a calldata provided list of attesters
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract TrustManagerExternalAttesterList is IRegistry, TrustManager {
    using TrustLib for AttestationRecord;

    /**
     * @inheritdoc IERC7484
     */
    function check(address module, address[] calldata attesters, uint256 threshold) external view {
        uint256 attestersLength = attesters.length;
        if (attestersLength == 0 || threshold == 0) {
            revert NoTrustedAttestersFound();
        } else if (attestersLength < threshold) {
            revert InsufficientAttestations();
        }

        address _attesterCache;
        for (uint256 i; i < attestersLength; ++i) {
            address attester = attesters[i];
            if (attester <= _attesterCache) revert InvalidTrustedAttesterInput();
            else _attesterCache = attester;
            if ($getAttestation(module, attester).checkValid(ZERO_MODULE_TYPE)) {
                --threshold;
            }
            if (threshold == 0) return;
        }
        revert InsufficientAttestations();
    }

    /**
     * @inheritdoc IERC7484
     */
    function check(address module, ModuleType moduleType, address[] calldata attesters, uint256 threshold) external view {
        uint256 attestersLength = attesters.length;
        if (attestersLength == 0 || threshold == 0) {
            revert NoTrustedAttestersFound();
        } else if (attestersLength < threshold) {
            revert InsufficientAttestations();
        }

        address _attesterCache;
        for (uint256 i; i < attestersLength; ++i) {
            address attester = attesters[i];

            if (attester <= _attesterCache) revert InvalidTrustedAttesterInput();
            else _attesterCache = attester;
            if ($getAttestation(module, attester).checkValid(moduleType)) {
                --threshold;
            }
            if (threshold == 0) return;
        }
        revert InsufficientAttestations();
    }
}
