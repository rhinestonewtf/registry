// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/RSModuleRegistry.sol";

import { IRSSchema, SchemaRecord } from "../src/interface/IRSSchema.sol";
import { ISchemaResolver } from "../src/resolver/ISchemaResolver.sol";
import { InvalidSchema } from "../src/Common.sol";

import { RSSchemaTest } from "./RSSchema.t.sol";

contract MockModule {
    constructor(uint256 param) { }

    function foo() public pure returns (uint256) {
        return 42;
    }
}

/// @title RSModuleRegistryTest
/// @author zeroknots
contract RSModuleRegistryTest is RSSchemaTest {
    RSModuleRegistry moduleRegistry;

    function setUp() public virtual override {
        super.setUp();
        moduleRegistry = new RSModuleRegistry();
        schema = RSSchema(address(moduleRegistry));
    }

    function testDeploy() public returns (bytes32 schemaId, address moduleAddr) {
        bytes32 schemaId =
            registerSchema(RSSchema(address(moduleRegistry)), "test", simpleResolver, true);
        moduleAddr = moduleRegistry.deploy({
            code: type(MockModule).creationCode,
            deployParams: abi.encode(1234),
            salt: 0,
            data: "",
            schemaId: schemaId
        });
        assertFalse(address(0) == moduleAddr);

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        moduleAddr = moduleRegistry.deploy({
            code: type(MockModule).creationCode,
            deployParams: abi.encode(1234),
            salt: 0,
            data: "",
            schemaId: "8181"
        });
    }
}
