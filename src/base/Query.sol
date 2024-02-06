// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IQuery } from "../interface/IQuery.sol";
import {
    AttestationRecord,
    SchemaUID,
    SchemaRecord,
    AttestationResolve,
    Attestation,
    ResolverUID,
    ResolverRecord,
    ModuleRecord
} from "./Attestation.sol";

import { ZERO_TIMESTAMP } from "../Common.sol";

/**
 * @title Query
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 * Implements EIP-7484 to query attestations stored in the registry.
 * @dev This contract is abstract and provides utility functions to query attestations.
 */
abstract contract Query is IQuery {
    /**
     * @inheritdoc IQuery
     */
    function check(
        address module,
        address attester
    )
        public
        view
        override(IQuery)
        returns (uint256 attestedAt)
    {
        AttestationRecord storage attestation = _getAttestation(module, attester);

        // attestedAt = attestation.time;
        uint256 expirationTime; // = attestation.expirationTime;
        uint256 revocationTime; // = attestation.revocationTime;

        // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
        // @dev the solidity version of the assembly code is above
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

    /**
     * @inheritdoc IQuery
     */
    function checkN(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        override(IQuery)
        returns (uint256[] memory attestedAtArray)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;
        attestedAtArray = new uint256[](attestersLength);

        for (uint256 i; i < attestersLength; ++i) {
            AttestationRecord storage attestation =
                _getAttestation({ moduleAddress: module, attester: attesters[i] });

            uint256 attestationTime; // = attestation.time;
            uint256 expirationTime; // = attestation.expirationTime;
            uint256 revocationTime; // = attestation.revocationTime;

            // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
            // @dev the solidity version of the assembly code is above
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

    /**
     * @inheritdoc IQuery
     */
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
            AttestationRecord storage attestation =
                _getAttestation({ moduleAddress: module, attester: attesters[i] });

            uint256 attestationTime; // = attestation.time;
            uint256 expirationTime; // = attestation.expirationTime;
            uint256 revocationTime; // = attestation.revocationTime;

            // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
            // @dev the solidity version of the assembly code is above
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

    /**
     * @inheritdoc IQuery
     */
    function findAttestation(
        address module,
        address attesters
    )
        public
        view
        override(IQuery)
        returns (AttestationRecord memory attestation)
    {
        attestation = _getAttestation(module, attesters);
    }

    /**
     * @inheritdoc IQuery
     */
    function findAttestations(
        address module,
        address[] memory attesters
    )
        external
        view
        override(IQuery)
        returns (AttestationRecord[] memory attestations)
    {
        uint256 attesterssLength = attesters.length;
        attestations = new AttestationRecord[](attesterssLength);
        for (uint256 i; i < attesterssLength; ++i) {
            attestations[i] = findAttestation(module, attesters[i]);
        }
    }

    /**
     * @notice Internal function to retrieve an attestation record.
     *
     * @dev This is a virtual function and is meant to be overridden in derived contracts.
     *
     * @param moduleAddress The address of the module for which the attestation is retrieved.
     * @param attester The address of the attester whose record is being retrieved.
     *
     * @return Attestation record associated with the given module and attester.
     */
    function _getAttestation(
        address moduleAddress,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage);
}
