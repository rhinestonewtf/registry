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

        SchemaRecord memory schema = instance.registry.getSchema(schemaUID);
        assertEq(schema.schema, "Test ABI 2");
    }

    function testRegisterSchema__RevertWhen__AlreadyExists() public {
        SchemaUID schemaUID = instance.registerSchema("Test ABI 2", ISchemaValidator(address(0)));
        assertTrue(SchemaUID.unwrap(schemaUID) != bytes32(0));

        vm.expectRevert(abi.encodeWithSelector(ISchema.AlreadyExists.selector));
        schemaUID = instance.registerSchema("Test ABI 2", ISchemaValidator(address(0)));
    }

    function testRegisterResolver() public {
        ResolverUID resolverUID = instance.registerResolver(simpleResolver);
        assertTrue(ResolverUID.unwrap(resolverUID) != bytes32(0));
    }

    function testRegisterResolver__RevertWhen__InvalidResolver() public {
        vm.expectRevert(abi.encodeWithSelector(InvalidResolver.selector));
        instance.registerResolver(IResolver(address(0)));
    }

    function testRegisterResolver__RevertWhen__AlreadyExists() public {
        ResolverUID resolverUID = instance.registerResolver(simpleResolver);
        assertTrue(ResolverUID.unwrap(resolverUID) != bytes32(0));

        vm.expectRevert(abi.encodeWithSelector(ISchema.AlreadyExists.selector));
        resolverUID = instance.registerResolver(simpleResolver);
    }

    function testSetResolver() public {
        address resolverOwner = address(this);
        ResolverUID resolverUID = instance.registerResolver(simpleResolver);
        ResolverRecord memory resolver = instance.registry.getResolver(resolverUID);
        assertEq(resolver.resolverOwner, resolverOwner);
        assertEq(address(resolver.resolver), address(simpleResolver));

        instance.registry.setResolver(resolverUID, IResolver(address(0x69)));
        resolver = instance.registry.getResolver(resolverUID);
        assertEq(address(resolver.resolver), address(0x69));
    }
}
