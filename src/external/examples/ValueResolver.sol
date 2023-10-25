// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ResolverBase, AttestationRecord, ModuleRecord } from "../ResolverBase.sol";

/**
 * @title ValueResolver
 * @author zeroknots
 * @notice A resolver for value (ETH) attestations.
 */
contract ValueResolver is ResolverBase {
    uint256 immutable fee = 10;

    constructor(address rs) ResolverBase(rs) { }

    function onAttest(
        AttestationRecord calldata attestation,
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
        AttestationRecord calldata attestation,
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
}
