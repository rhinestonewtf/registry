// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/resolver/ISchemaResolver.sol";
import "../src/interface/IRSSchema.sol";
import { DebugResolver } from "../src/resolver/examples/DebugResolver.sol";

import "./utils/BaseTest.t.sol";

/// @title RSSchemaTest
/// @author zeroknots
contract RSSchemaTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    DebugResolver simpleResolver;

    function setUp() public virtual override {
        super.setUp();
        simpleResolver = new DebugResolver(address(instancel1.registry));
    }

    function testRegisterSchema() public {
        bytes32 schemaId =
            instancel1.registerSchema("Test ABI 2", ISchemaResolver(address(0)), true);
        assertTrue(schemaId != bytes32(0), "schemaId should not be empty");
    }

    function testRegisterSchemaWitSameSchema() public {
        bytes32 schemaId = instancel1.registerSchema("same", ISchemaResolver(address(0)), true);

        vm.expectRevert(abi.encodeWithSelector(IRSSchema.AlreadyExists.selector));
        bytes32 schemaId2 = instancel1.registerSchema("same", ISchemaResolver(address(0)), true);
    }

    function testUpdateBridges() public {
        bytes32 schemaId =
            instancel1.registerSchema("Test ABI 2", ISchemaResolver(address(0)), true);
        address[] memory bridges = new address[](2);
        bridges[0] = address(1);
        bridges[1] = address(2);

        instancel1.registry.setBridges(schemaId, bridges);
    }

    function testFailUnauthorizedUpdateBridges() public {
        bytes32 schemaId =
            instancel1.registerSchema("Test ABI 2", ISchemaResolver(address(0)), true);
        address[] memory bridges = new address[](2);
        bridges[0] = address(1);
        bridges[1] = address(2);

        address bob = address(0x1234);

        vm.prank(bob);
        instancel1.registry.setBridges(schemaId, bridges);
    }

    function testSameUIDOnL2() public {
        assertTrue(false);
    }

    function testUpdateResolver() public {
        assertTrue(false);
    }
}
