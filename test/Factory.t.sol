// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";
import "../script/Create2Factory.sol";

contract MockModuleFoo {
    uint256 public value;

    constructor() {
        value = 1;
    }
}

contract FactoryTest is BaseTest {
    ImmutableCreate2Factory factory;

    function setUp() public override {
        super.setUp();
    }

    function test_EnsureFactoryCalc() public {
        bytes32 salt = 0x05a40beaf368eb6b2bc5665901a885c044c19346fc828ba80a35fe4cc30d0000;

        vm.startPrank(address(0x05a40beAF368EB6b2bc5665901a885C044C19346));
        address moduleAddress = registry.calcModuleAddress(salt, type(MockModuleFoo).creationCode);

        address deployedAddr = registry.deployModule(salt, defaultResolverUID, type(MockModuleFoo).creationCode, "", "");
        vm.stopPrank();
        assertTrue(moduleAddress == deployedAddr);
    }
}
