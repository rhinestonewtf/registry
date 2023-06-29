// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IRSSchema, SchemaRecord } from "../src/interface/IRSSchema.sol";
import { ISchemaResolver } from "../src/resolver/ISchemaResolver.sol";
import { InvalidSchema } from "../src/Common.sol";
import "./utils/BaseTest.t.sol";

/// @title RSModuleTest
/// @author zeroknots
contract RSModuleTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testDeployWithArgs() public returns (bytes32 schemaId, address moduleAddr) {
        schemaId = instancel1.registerSchema("Test ABI 123", ISchemaResolver(address(0)), true);

        bytes memory bytecode = type(MockModuleWithArgs).creationCode;
        moduleAddr = instancel1.deployAndRegister({
            schemaId: schemaId,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_131)
        });
    }

    function testDeployNoArgs() public returns (bytes32 schemaId, address moduleAddr) {
        schemaId = instancel1.registerSchema("Test ABI 123", ISchemaResolver(address(0)), true);

        bytes memory bytecode = type(MockModule).creationCode;
        moduleAddr = instancel1.deployAndRegister({
            schemaId: schemaId,
            bytecode: bytecode,
            constructorArgs: bytes("")
        });
    }

    function testNonexistingModule() public {
        // TODO
        bytes32 schemaId = instancel1.registerSchema("Test ABI 123", ISchemaResolver(address(0)), true);

        address module = makeAddr("doesntExist");
        vm.expectRevert();
        instancel1.registry.register(schemaId, module, "");


    }

    function testReRegisterModule() public {
        bytes32 schemaId = instancel1.registerSchema("Test ABI 123", ISchemaResolver(address(0)), true);

        bytes memory bytecode = type(MockModule).creationCode;
        address moduleAddr = instancel1.deployAndRegister({
            schemaId: schemaId,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_132)
        });
        vm.expectRevert(abi.encodeWithSelector(RSModule.AlreadyRegistered.selector, moduleAddr));
        instancel1.registry.register(schemaId, moduleAddr, "");
    }
}
