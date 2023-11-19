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

import "forge-std/console2.sol";

/**
 * @title Query
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 * Implements EIP-7484 to query attestations stored in the registry.
 * @dev This contract is abstract and provides utility functions to query attestations.
 */
abstract contract Query is IQuery {
    // @Todo: remove
    function mock(address module, address attester) public {
        AttestationRecord storage attestation = _getAttestation(module, attester);
        attestation.time = uint48(0x123);
        attestation.expirationTime = uint48(0x567);
        attestation.revocationTime = uint48(0x899);
    }
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

        // uint256 attestationTime = attestation.time;
        // uint256 expirationTime = attestation.expirationTime;
        // uint256 revocationTime = attestation.revocationTime;

        // if (expirationTime != ZERO_TIMESTAMP) {
        //     attestedAt = attestationTime;
        // } else if (expirationTime > block.timestamp) {
        //     attestedAt = attestationTime;
        // }

        // if (attestationTime == ZERO_TIMESTAMP) {
        //     revert AttestationNotFound();
        // }

        // if (revocationTime != ZERO_TIMESTAMP) {
        //     revert RevokedAttestation(attestation.attester);
        // }

        uint256 attestationTime;
        uint256 expirationTime;
        uint256 revocationTime;

        bytes32 times;

        assembly {
            times := sload(add(attestation.slot, 1))
        }

        console2.logBytes32(times);

        if (expirationTime != ZERO_TIMESTAMP) {
            attestedAt = attestationTime;
        } else if (expirationTime > block.timestamp) {
            attestedAt = attestationTime;
        }

        if (attestationTime == ZERO_TIMESTAMP) {
            revert AttestationNotFound();
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
            if (attestation.revocationTime != ZERO_TIMESTAMP) {
                revert RevokedAttestation(attestation.attester);
            }

            uint256 expirationTime = attestation.expirationTime;
            if (expirationTime != ZERO_TIMESTAMP && expirationTime < timeNow) {
                revert AttestationNotFound();
            }

            uint256 attestationTime = attestation.time;
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

            if (attestation.revocationTime != ZERO_TIMESTAMP) {
                attestedAtArray[i] = 0;
                continue;
            }

            uint256 expirationTime = attestation.expirationTime;
            uint256 attestedAt = expirationTime != ZERO_TIMESTAMP && expirationTime < timeNow
                ? ZERO_TIMESTAMP
                : attestation.time;
            attestedAtArray[i] = attestedAt;
            if (attestedAt == ZERO_TIMESTAMP) continue;
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
