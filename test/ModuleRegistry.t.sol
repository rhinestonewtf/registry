// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISchema, SchemaRecord } from "../src/interface/ISchema.sol";
import { IResolver } from "../src/external/IResolver.sol";
import { InvalidSchema } from "../src/Common.sol";
import "./utils/BaseTest.t.sol";

/// @title ModuleTest
/// @author zeroknots
contract ModuleTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testDeployWithArgs() public returns (SchemaUID schemaUID, address moduleAddr) {
        schemaUID = instancel1.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        bytes memory bytecode = type(MockModuleWithArgs).creationCode;
        moduleAddr = instancel1.deployAndRegister({
            resolverUID: defaultResolver,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_131)
        });
    }

    function testDeployNoArgs() public returns (SchemaUID schemaUID, address moduleAddr) {
        schemaUID = instancel1.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        bytes memory bytecode = type(MockModule).creationCode;
        moduleAddr = instancel1.deployAndRegister({
            resolverUID: defaultResolver,
            bytecode: bytecode,
            constructorArgs: bytes("")
        });
    }

    function testNonexistingModule() public {
        // TODO
        SchemaUID schemaUID =
            instancel1.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        address module = makeAddr("doesntExist");
        vm.expectRevert();
        instancel1.registry.register(defaultResolver, module, "");
    }

    function testReRegisterModule() public {
        SchemaUID schemaUID =
            instancel1.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        bytes memory bytecode = type(MockModule).creationCode;
        address moduleAddr = instancel1.deployAndRegister({
            resolverUID: defaultResolver,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_132)
        });
        vm.expectRevert(abi.encodeWithSelector(IModule.AlreadyRegistered.selector, moduleAddr));
        instancel1.registry.register(defaultResolver, moduleAddr, "");
    }
}
