// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import "../interface/IAttestation.sol";
import { EIP712Verifier } from "./EIP712Verifier.sol";
import { ZERO_ADDRESS, AccessDenied, uncheckedInc } from "../Common.sol";
import { AttestationDataRef, writeAttestationData, readAttestationData } from "../DataTypes.sol";

abstract contract AttestationResolve is IAttestation, EIP712Verifier {
    using Address for address payable;
    /**
     * @dev Resolves a new attestation or a revocation of an existing attestation.
     *
     * @param resolverUID The schema of the attestation.
     * @param attestation The data of the attestation to make/revoke.
     * @param value An explicit ETH amount to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */

    function _resolveAttestation(
        ResolverUID resolverUID,
        AttestationRecord memory attestation,
        uint256 value,
        bool isRevocation,
        uint256 availableValue,
        bool last
    )
        internal
        returns (uint256)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        IResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) {
            // Ensure that we don't accept payments if there is no resolver.
            if (value != 0) {
                revert NotPayable();
            }

            return 0;
        }

        // Ensure that we don't accept payments which can't be forwarded to the resolver.
        if (value != 0 && !resolverContract.isPayable()) {
            revert NotPayable();
        }

        // Ensure that the attester/revoker doesn't try to spend more than available.
        if (value > availableValue) {
            revert InsufficientValue();
        }

        // Ensure to deduct the sent value explicitly.
        unchecked {
            availableValue -= value;
        }

        if (isRevocation) {
            if (!resolverContract.revoke{ value: value }(attestation)) {
                revert InvalidRevocation();
            }
        } else if (!resolverContract.attest{ value: value }(attestation)) {
            revert InvalidAttestation();
        }

        if (last) {
            _refund(availableValue);
        }

        return value;
    }

    /**
     * @dev Resolves multiple attestations or revocations of existing attestations.
     *
     * @param resolverUID THe bytes32 uid of the resolver
     * @param attestations The data of the attestations to make/revoke.
     * @param values Explicit ETH amounts to send to the resolver.
     * @param isRevocation Whether to resolve an attestation or its revocation.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _resolveAttestations(
        ResolverUID resolverUID,
        AttestationRecord[] memory attestations,
        uint256[] memory values,
        bool isRevocation,
        uint256 availableValue,
        bool last
    )
        internal
        returns (uint256)
    {
        uint256 length = attestations.length;
        if (length == 1) {
            return _resolveAttestation(
                resolverUID, attestations[0], values[0], isRevocation, availableValue, last
            );
        }
        ResolverRecord memory resolver = getResolver(resolverUID);
        IResolver resolverContract = resolver.resolver;
        if (address(resolverContract) == ZERO_ADDRESS) {
            // Ensure that we don't accept payments if there is no resolver.
            for (uint256 i; i < length; i = uncheckedInc(i)) {
                if (values[i] != 0) {
                    revert NotPayable();
                }
            }

            return 0;
        }

        uint256 totalUsedValue;

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            uint256 value = values[i];

            // Ensure that we don't accept payments which can't be forwarded to the resolver.
            if (value != 0 && !resolverContract.isPayable()) {
                revert NotPayable();
            }

            // Ensure that the attester/revoker doesn't try to spend more than available.
            if (value > availableValue) {
                revert InsufficientValue();
            }

            // Ensure to deduct the sent value explicitly and add it to the total used value by the batch.
            unchecked {
                availableValue -= value;
                totalUsedValue += value;
            }
        }

        if (isRevocation) {
            if (!resolverContract.multiRevoke{ value: totalUsedValue }(attestations, values)) {
                revert InvalidRevocations();
            }
        } else if (!resolverContract.multiAttest{ value: totalUsedValue }(attestations, values)) {
            revert InvalidAttestations();
        }

        if (last) {
            _refund(availableValue);
        }

        return totalUsedValue;
    }

    /**
     * @dev Refunds remaining ETH amount to the attester.
     *
     * @param remainingValue The remaining ETH amount that was not sent to the resolver.
     */
    function _refund(uint256 remainingValue) private {
        if (remainingValue > 0) {
            // Using a regular transfer here might revert, for some non-EOA attesters, due to exceeding of the 2300
            // gas limit which is why we're using call instead (via sendValue), which the 2300 gas limit does not
            // apply for.
            payable(msg.sender).sendValue(remainingValue);
        }
    }

    function _getSchema(SchemaUID uid) internal view virtual returns (SchemaRecord storage);

    function getResolver(ResolverUID uid) public view virtual returns (ResolverRecord memory);

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        returns (ModuleRecord storage);
}
