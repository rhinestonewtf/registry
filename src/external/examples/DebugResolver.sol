// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console2.sol";
import { ResolverBase } from "../ResolverBase.sol";
import { AttestationRecord, ModuleRecord } from "../../DataTypes.sol";

/// @title DebugResolver
/// @author zeroknots
/// @notice A debug resolver for testing purposes.

contract DebugResolver is ResolverBase {
    constructor(address rs) ResolverBase(rs) { }

    function onAttest(
        AttestationRecord calldata attestation,
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
        AttestationRecord calldata, /*attestation*/
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
        ModuleRecord calldata module,
        uint256 value
    )
        internal
        override
        returns (bool)
    {
        return true;
    }

    function onPropagation(
        AttestationRecord calldata attestation,
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
