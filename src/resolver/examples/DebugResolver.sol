// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console2.sol";
import { SchemaResolver } from "../SchemaResolver.sol";
import { Attestation, Module } from "../../Common.sol";

/// @title DebugResolver
/// @author zeroknots
/// @notice ContractDescription

contract DebugResolver is SchemaResolver {
    constructor(address rs) SchemaResolver(rs) { }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    )
        internal
        view
        override
        returns (bool)
    {
        console2.log(attestation.attester);

        return true;
    }

    function onRevoke(
        Attestation calldata, /*attestation*/
        uint256 /*value*/
    )
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }

    function onModuleRegistration(
        Module calldata module,
        uint256 value
    )
        internal
        override
        returns (bool)
    {
        return true;
    }

    function onPropagation(
        Attestation calldata attestation,
        address sender,
        address to,
        uint256 toChainId,
        address moduleOnL2
    )
        internal
        override
        returns (bool)
    {
        return true;
    }
}
