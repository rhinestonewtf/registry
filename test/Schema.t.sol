// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/external/IResolver.sol";
import "../src/interface/ISchema.sol";
import { DebugResolver } from "../src/external/examples/DebugResolver.sol";
import { InvalidResolver } from "../src/Common.sol";

import "./utils/BaseTest.t.sol";

/// @title SchemaTest
/// @author zeroknots, kopy-kat
contract SchemaTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    DebugResolver simpleResolver;

    function setUp() public virtual override {
        super.setUp();
        simpleResolver = new DebugResolver(address(instance.registry));
    }

    function testRegisterSchema() public {
        SchemaUID schemaUID = instance.registerSchema("Test ABI 2", ISchemaValidator(address(0)));
        assertTrue(SchemaUID.unwrap(schemaUID) != bytes32(0));
    }

    function testRegisterSchema__RevertWhen__AlreadyExists() public {
        SchemaUID schemaUID = instance.registerSchema("Test ABI 2", ISchemaValidator(address(0)));
        assertTrue(SchemaUID.unwrap(schemaUID) != bytes32(0));

        vm.expectRevert(abi.encodeWithSelector(ISchema.AlreadyExists.selector));
        schemaUID = instance.registerSchema("Test ABI 2", ISchemaValidator(address(0)));
    }

    function registerResolver() public {
        ResolverUID rsolverUID = instance.registerResolver(simpleResolver);
        assertTrue(ResolverUID.unwrap(rsolverUID) != bytes32(0));
    }

    function registerResolver__RevertWhen__InvalidResolver() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidResolver.selector));
        instance.registerResolver(IResolver(address(0)));
    }

    function registerResolver__RevertWhen__AlreadyExists() public {
        ResolverUID rsolverUID = instance.registerResolver(simpleResolver);
        assertTrue(ResolverUID.unwrap(rsolverUID) != bytes32(0));

        vm.expectRevert(abi.encodeWithSelector(ISchema.AlreadyExists.selector));
        rsolverUID = instance.registerResolver(simpleResolver);
    }
}
