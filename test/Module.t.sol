// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISchema, SchemaRecord } from "../src/interface/ISchema.sol";
import "../src/lib/ModuleDeploymentLib.sol";
import { IResolver } from "../src/external/IResolver.sol";
import { InvalidSchema } from "../src/Common.sol";
import "./utils/BaseTest.t.sol";
import { IModule } from "../src/interface/IModule.sol";

/// @title ModuleTest
/// @author zeroknots
contract ModuleTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testDeployWithArgs() public returns (SchemaUID schemaUID, address moduleAddr) {
        schemaUID = instance.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        bytes memory bytecode = type(MockModuleWithArgs).creationCode;
        moduleAddr = instance.deployAndRegister({
            resolverUID: defaultResolver,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_131)
        });

        MockModuleWithArgs module = MockModuleWithArgs(moduleAddr);

        assertEq(module.readValue(), 313_131, "value should be set");
    }

    function testDeployNoArgs() public returns (SchemaUID schemaUID, address moduleAddr) {
        schemaUID = instance.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        bytes memory bytecode = type(MockModule).creationCode;
        moduleAddr = instance.deployAndRegister({
            resolverUID: defaultResolver,
            bytecode: bytecode,
            constructorArgs: bytes("")
        });
    }

    function testNonexistingModule__ShouldRevert() public {
        // TODO
        SchemaUID schemaUID = instance.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        address module = makeAddr("doesntExist");
        vm.expectRevert();
        instance.registry.register(defaultResolver, module, "");
    }

    function testReRegisterModule__ShouldRevert() public {
        SchemaUID schemaUID = instance.registerSchema("Test ABI 123", ISchemaValidator(address(0)));

        bytes memory bytecode = type(MockModule).creationCode;
        address moduleAddr = instance.deployAndRegister({
            resolverUID: defaultResolver,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_132)
        });
        vm.expectRevert(abi.encodeWithSelector(IModule.AlreadyRegistered.selector, moduleAddr));
        instance.registry.register(defaultResolver, moduleAddr, "");
    }

    function testExternalFactory() public {
        ExternalFactory factory = new ExternalFactory();

        bytes memory bytecode = type(MockModule).creationCode;

        bytes memory ExternalFactoryCallData =
            abi.encodeWithSelector(ExternalFactory.deploy.selector, bytecode, "", 123);

        address moduleAddr = instance.registry.deployViaFactory(
            address(factory), ExternalFactoryCallData, "foobar", defaultResolver
        );

        ModuleRecord memory record = instance.registry.getModule(moduleAddr);
        assertEq(record.implementation, moduleAddr);
        assertEq(record.sender, address(this));
    }

    function testCreate3() public {
        bytes memory bytecode = type(MockModule).creationCode;

        address moduleAddr = instance.registry.deployC3(bytecode, "", "1", "", defaultResolver);
        ModuleRecord memory record = instance.registry.getModule(moduleAddr);
        assertEq(record.implementation, moduleAddr);
        assertEq(record.sender, address(this));
    }
}

contract ExternalFactory {
    event ExternalFactoryDeploy(address moduleAddr);

    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt
    )
        external
        payable
        returns (address moduleAddr)
    {
        (moduleAddr,,) = ModuleDeploymentLib.deploy(code, deployParams, salt, 0);
        emit ExternalFactoryDeploy(moduleAddr);
    }
}
