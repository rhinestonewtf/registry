// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/RSSchema.sol";
import "../src/resolver/ISchemaResolver.sol";
import { SimpleResolver } from "./mock/SimpleResolver.sol";

/// @title RSSchemaTest
/// @author zeroknots
contract RSSchemaTest is Test {
    RSSchema schema;
    SimpleResolver simpleResolver;

    function setUp() public {
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
        return schema.register(abi, resolver, revocable);
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
}
