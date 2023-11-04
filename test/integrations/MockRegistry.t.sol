// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { BaseTest, RegistryTestLib, RegistryInstance } from "../utils/BaseTest.t.sol";
import { MockRegistry } from "../../src/integrations/MockRegistry.sol";

/// @title MockRegistryTest
/// @author kopy-kat
contract MockRegistryTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    MockRegistry mockRegistry;

    function setUp() public virtual override {
        super.setUp();
        mockRegistry = new MockRegistry();
    }

    function testCheck() public {
        uint256 attestedAt = mockRegistry.check(address(this), address(this));
        assertGt(attestedAt, uint256(0));
    }

    function testCheckN() public {
        uint256[] memory attestedAtArray = mockRegistry.checkN(address(this), new address[](1), 1);
        for (uint256 i; i < attestedAtArray.length; ++i) {
            assertGt(attestedAtArray[i], uint256(0));
        }
    }

    function testCheckNUnsafe() public {
        uint256[] memory attestedAtArray =
            mockRegistry.checkNUnsafe(address(this), new address[](1), 1);
        for (uint256 i; i < attestedAtArray.length; ++i) {
            assertGt(attestedAtArray[i], uint256(0));
        }
    }
}
