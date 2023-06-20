// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/console2.sol";
import { SchemaResolver } from "../../src/resolver/SchemaResolver.sol";
import { Attestation } from "../../src/Common.sol";

/// @title SimpleResolver
/// @author zeroknots
/// @notice ContractDescription

contract SimpleResolver is SchemaResolver {
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
}
