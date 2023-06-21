// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RSSchema.sol";
import "../src/resolver/ISchemaResolver.sol";
import { SimpleResolver } from "./mock/SimpleResolver.sol";

import { AccessDenied } from "../src/Common.sol";

/// @title RSSchemaTest
/// @author zeroknots
contract RSSchemaTest is Test {
    RSSchema schema;
    SimpleResolver simpleResolver;

    function setUp() public virtual {
        schema = new RSSchema();
        simpleResolver = new SimpleResolver(address(schema));
    }

    function testRegisterSchema(
        string memory abi,
        ISchemaResolver resolver,
        bool revocable
    )
        public
        returns (bytes32)
    {
        return (registerSchema(schema, abi, resolver, revocable));
    }

    function registerSchema(
        RSSchema registry,
        string memory abi,
        ISchemaResolver resolver,
        bool revocable
    )
        internal
        returns (bytes32 schemaId)
    {
        return schema.registerSchema(abi, resolver, revocable);
    }

    function testUpdateBridges() public {
        string memory abi = "test";
        ISchemaResolver resolver = simpleResolver;

        bytes32 schemaId = testRegisterSchema({ abi: abi, resolver: resolver, revocable: true });

        address[] memory bridges = new address[](2);
        bridges[0] = address(1);
        bridges[1] = address(2);

        schema.setBridges(schemaId, bridges);
    }

    function testFailUnauthorizedUpdateBridges() public {
        string memory abi = "test";
        ISchemaResolver resolver = simpleResolver;

        bytes32 schemaId = testRegisterSchema({ abi: abi, resolver: resolver, revocable: true });

        address[] memory bridges = new address[](2);
        bridges[0] = address(1);
        bridges[1] = address(2);

        address bob = address(0x1234);

        vm.prank(bob);
        schema.setBridges(schemaId, bridges);
    }
}
