// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";

contract ResolverTest is BaseTest {
    modifier whenRegisteringResolver() {
        _;
    }

    function test_WhenNewResolver() external whenRegisteringResolver prankWithAccount(opsEntity1) {
        // It should work.

        MockResolver newResolver = new MockResolver(false);
        registry.registerResolver(IExternalResolver(address(newResolver)));
    }

    function test_WhenResolverAlreadyRegistered() external whenRegisteringResolver {
        // It should revert.

        MockResolver newResolver = new MockResolver(false);
        registry.registerResolver(IExternalResolver(address(newResolver)));
        vm.expectRevert();
        registry.registerResolver(IExternalResolver(address(newResolver)));
    }

    modifier whenUpdatingResolver() {
        _;
    }

    function test_WhenUsingUnauthorizedAccount() external whenUpdatingResolver {
        // It should revert.
        MockResolver newResolver = new MockResolver(false);
        vm.prank(opsEntity1.addr);
        ResolverUID resolverUID = registry.registerResolver(IExternalResolver(address(newResolver)));

        vm.expectRevert();
        registry.setResolver(resolverUID, IExternalResolver(address(newResolver)));
    }

    function test_WhenUsingAuthorizedAccount() external whenUpdatingResolver {
        MockResolver newResolver = new MockResolver(false);
        vm.prank(opsEntity1.addr);
        ResolverUID resolverUID = registry.registerResolver(IExternalResolver(address(newResolver)));

        MockResolver newResolver2 = new MockResolver(false);
        vm.prank(opsEntity1.addr);
        registry.setResolver(resolverUID, IExternalResolver(address(newResolver2)));

        // ResolverRecord memory record = registry.resolvers(resolverUID);
        // assertEq(address(record.resolver), address(newResolver2));
    }
}
