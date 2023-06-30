// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {
    AccessDenied,
    NO_EXPIRATION_TIME,
    NotFound,
    uncheckedInc,
    Attestation,
    Module
} from "../Common.sol";

import { ISchemaResolver } from "./ISchemaResolver.sol";

/**
 * @title A base resolver contract
 *
 * @author zeroknots.eth
 */
abstract contract SchemaResolver is ISchemaResolver {
    error InsufficientValue();
    error NotPayable();
    error InvalidRS();

    // The version of the contract.
    string public constant VERSION = "0.1";

    // The global Rhinestone Registry contract.
    address internal immutable _rs;

    /**
     * @dev Creates a new resolver.
     *
     * @param rs The address of the global RS contract.
     */
    constructor(address rs) {
        if (rs == address(0)) {
            revert InvalidRS();
        }
        _rs = rs;
    }

    /**
     * @dev Ensures that only the RS contract can make this call.
     */
    modifier onlyRS() {
        _onlyRSRegistry();
        _;
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function isPayable() public pure virtual returns (bool) {
        return false;
    }

    /**
     * @dev ETH callback.
     */
    receive() external payable virtual {
        if (!isPayable()) {
            revert NotPayable();
        }
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function attest(Attestation calldata attestation) external payable onlyRS returns (bool) {
        return onAttest(attestation, msg.value);
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function moduleRegistration(Module calldata module) external payable onlyRS returns (bool) {
        return onModuleRegistration(module, msg.value);
    }

    /**
     * @inheritdoc ISchemaResolver
     */

    function propagation(
        Attestation calldata attestation,
        address sender,
        address to,
        uint256 toChainId,
        address moduleOnL2
    )
        external
        payable
        returns (bool)
    {
        return onPropagation(attestation, sender, to, toChainId, moduleOnL2);
    }
    /**
     * @inheritdoc ISchemaResolver
     */

    function multiAttest(
        Attestation[] calldata attestations,
        uint256[] calldata values
    )
        external
        payable
        onlyRS
        returns (bool)
    {
        uint256 length = attestations.length;

        // We are keeping track of the remaining ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 remainingValue = msg.value;

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // Ensure that the attester/revoker doesn't try to spend more than available.
            uint256 value = values[i];
            if (value > remainingValue) {
                revert InsufficientValue();
            }

            // Forward the attestation to the underlying resolver and revert in case it isn't approved.
            if (!onAttest(attestations[i], value)) {
                return false;
            }

            unchecked {
                // Subtract the ETH amount, that was provided to this attestation, from the global remaining ETH amount.
                remainingValue -= value;
            }
        }

        return true;
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function revoke(Attestation calldata attestation) external payable onlyRS returns (bool) {
        return onRevoke(attestation, msg.value);
    }

    /**
     * @inheritdoc ISchemaResolver
     */
    function multiRevoke(
        Attestation[] calldata attestations,
        uint256[] calldata values
    )
        external
        payable
        onlyRS
        returns (bool)
    {
        uint256 length = attestations.length;

        // We are keeping track of the remaining ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 remainingValue = msg.value;

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // Ensure that the attester/revoker doesn't try to spend more than available.
            uint256 value = values[i];
            if (value > remainingValue) {
                revert InsufficientValue();
            }

            // Forward the revocation to the underlying resolver and revert in case it isn't approved.
            if (!onRevoke(attestations[i], value)) {
                return false;
            }

            unchecked {
                // Subtract the ETH amount, that was provided to this attestation, from the global remaining ETH amount.
                remainingValue -= value;
            }
        }

        return true;
    }

    /**
     * @dev A resolver callback that should be implemented by child contracts.
     *
     * @param attestation The new attestation.
     * @param value An explicit ETH amount that was sent to the resolver. Please note that this value is verified in
     * both attest() and multiAttest() callbacks RS-only callbacks and that in case of multi attestations, it'll
     * usually hold that msg.value != value, since msg.value aggregated the sent ETH amounts for all the attestations
     * in the batch.
     *
     * @return Whether the attestation is valid.
     */
    function onAttest(
        Attestation calldata attestation,
        uint256 value
    )
        internal
        virtual
        returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     * @param value An explicit ETH amount that was sent to the resolver. Please note that this value is verified in
     * both revoke() and multiRevoke() callbacks RS-only callbacks and that in case of multi attestations, it'll
     * usually hold that msg.value != value, since msg.value aggregated the sent ETH amounts for all the attestations
     * in the batch.
     *
     * @return Whether the attestation can be revoked.
     */
    function onRevoke(
        Attestation calldata attestation,
        uint256 value
    )
        internal
        virtual
        returns (bool);

    function onModuleRegistration(
        Module calldata module,
        uint256 value
    )
        internal
        virtual
        returns (bool);

    function onPropagation(
        Attestation calldata attestation,
        address sender,
        address to,
        uint256 toChainId,
        address moduleOnL2
    )
        internal
        virtual
        returns (bool);

    /**
     * @dev Ensures that only the RS contract can make this call.
     */
    function _onlyRSRegistry() private view {
        if (msg.sender != _rs) {
            revert AccessDenied();
        }
    }
}
