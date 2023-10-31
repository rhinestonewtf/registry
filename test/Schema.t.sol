// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/external/IResolver.sol";
import "../src/interface/ISchema.sol";
import { DebugResolver } from "../src/external/examples/DebugResolver.sol";

import "./utils/BaseTest.t.sol";

/// @title SchemaTest
/// @author zeroknots
contract SchemaTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    DebugResolver simpleResolver;

    function setUp() public virtual override {
        super.setUp();
        simpleResolver = new DebugResolver(address(instance.registry));
    }

    function testRegisterSchema() public {
        SchemaUID schemaId = instance.registerSchema("Test ABI 2", ISchemaValidator(address(0)));
        assertTrue(SchemaUID.unwrap(schemaId) != bytes32(0), "schemaId should not be empty");
    }

    function testRegisterSchemaWitSameSchema() public {
        SchemaUID schemaId = instance.registerSchema("same", ISchemaValidator(address(0)));

        vm.expectRevert(abi.encodeWithSelector(ISchema.AlreadyExists.selector));
        SchemaUID schemaId2 = instance.registerSchema("same", ISchemaValidator(address(0)));
    }

    function testSameUIDOnL2() public {
        // TODO
        assertTrue(true);
    }

    function testUpdateResolver() public {
        // TODO
        assertTrue(true);
    }
}
