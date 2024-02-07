// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ResolverTest {
    modifier whenRegisteringResolver() {
        _;
    }

    function test_WhenNewResolver() external whenRegisteringResolver {
        // It should work.
    }

    function test_WhenResolverAlreadyRegistered() external whenRegisteringResolver {
        // It should revert.
    }

    modifier whenUpdatingResolver() {
        _;
    }

    function test_WhenUsingUnauthorizedAccount() external whenUpdatingResolver {
        // It should revert.
    }

    function test_WhenUsingAuthorizedAccount() external whenUpdatingResolver {
        // It should update.
    }
}
