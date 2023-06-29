// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../SchemaResolver.sol";
import "../../Common.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title TokenizedResolver
/// @author zeroknots
/// @notice ContractDescription

contract TokenizedResolver is SchemaResolver {
    using SafeERC20 for IERC20;

    IERC20 private immutable token;

    uint256 immutable fee = 10;

    constructor(address rs, address tokenAddr) SchemaResolver(rs) {
        token = IERC20(tokenAddr);
    }

    function onAttest(
        Attestation calldata attestation,
        uint256 value
    )
        internal
        virtual
        override
        returns (bool)
    {
        token.safeTransferFrom(attestation.attester, address(this), fee);
        return true;
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
}
