// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../SchemaResolver.sol";
import "../../Common.sol";

/// @title ValueResolver
/// @author zeroknots
/// @notice ContractDescription

contract ValueResolver is SchemaResolver {
    uint256 immutable fee = 10;

    constructor(address rs) SchemaResolver(rs) { }

    function onAttest(
        Attestation calldata attestation,
        uint256 value
    )
        internal
        virtual
        override
        returns (bool)
    {
      return msg.value > fee;
    }

    function onRevoke(
        Attestation calldata attestation,
        uint256 value
    )
        internal
        virtual
        override
        returns (bool)
    {
        return true;
    }

    function isPayable() public pure override returns (bool) {
        return true;
    }
}
