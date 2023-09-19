// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "../interface/IQuery.sol";
import "./Attestation.sol";

import {
    AccessDenied, NotFound, NO_EXPIRATION_TIME, InvalidLength, uncheckedInc
} from "../Common.sol";
/**
 * @title Query
 * @author rhinestone | zeroknots.eth, Konrad Kopp(@kopy-kat)
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
        returns (uint48 listedAt, uint48 revokedAt)
    {
        AttestationRecord storage attestation = _getAttestation(module, attester);

        uint48 expirationTime = attestation.expirationTime;
        listedAt = expirationTime != 0 && expirationTime < block.timestamp ? 0 : attestation.time;
        if (listedAt == 0) revert AttestationNotFound();

        revokedAt = attestation.revocationTime;
        if (revokedAt != 0) revert RevokedAttestation(attestation.attester);
    }

    /**
     * @inheritdoc IQuery
     */
    function verify(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        override(IQuery)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;

        for (uint256 i; i < attestersLength; i = uncheckedInc(i)) {
            AttestationRecord storage attestation = _getAttestation(module, attesters[i]);

            if (attestation.revocationTime != 0) {
                revert RevokedAttestation(attestation.attester);
            }

            uint48 expirationTime = attestation.expirationTime;
            if (expirationTime != 0 && expirationTime < timeNow) {
                revert AttestationNotFound();
            }

            if (attestation.time == 0) continue;

            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return;
        revert InsufficientAttestations();
    }

    /**
     * @inheritdoc IQuery
     */
    function verifyUnsafe(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;

        for (uint256 i; i < attestersLength; i = uncheckedInc(i)) {
            if (threshold == 0) return;
            AttestationRecord storage attestation = _getAttestation(module, attesters[i]);

            if (attestation.revocationTime != 0) continue;

            uint48 expirationTime = attestation.expirationTime;
            uint48 listedAt = expirationTime != 0 && expirationTime < timeNow ? 0 : attestation.time;
            if (listedAt == 0) continue;

            --threshold;
        }
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
        for (uint256 i; i < attesterssLength; i = uncheckedInc(i)) {
            attestations[i] = findAttestation(module, attesters[i]);
        }
    }
    /**
     * @notice Internal function to retrieve an attestation record.
     *
     * @dev This is a virtual function and is meant to be overridden in derived contracts.
     *
     * @param module The address of the module for which the attestation is retrieved.
     * @param attester The address of the attester whose record is being retrieved.
     *
     * @return Attestation record associated with the given module and attester.
     */

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage);
}
