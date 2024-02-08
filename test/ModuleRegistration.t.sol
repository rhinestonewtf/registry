// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";
import "./mocks/MockModule.sol";

contract ModuleRegistrationTest is BaseTest {
    function test_WhenDeployingViaRegistry() public prankWithAccount(moduleDev1) {
        bytes32 salt = keccak256(abi.encodePacked("ModuleRegistration", address(this)));

        bytes memory bytecode = type(MockModule).creationCode;

        address moduleAddr = registry.deployModule(salt, defaultResolverUID, bytecode, "", "data");
        ModuleRecord memory record = registry.getRegisteredModules(moduleAddr);
        assertTrue(record.resolverUID == defaultResolverUID);
    }

    function test_WhenDeployingViaRegistryWithArgs() public prankWithAccount(moduleDev1) {
        bytes32 salt = keccak256(abi.encodePacked("ModuleRegistration", address(this)));

        bytes memory bytecode = type(MockModuleWithArgs).creationCode;

        address moduleAddr =
            registry.deployModule(salt, defaultResolverUID, bytecode, abi.encode(313_131), "");
    }

    function test_WhenRegisteringAModuleOnAnInvalidResolverUID()
        external
        prankWithAccount(moduleDev1)
    {
        MockModule newModule = new MockModule();
        // It should revert.
        ResolverUID invalidUID = ResolverUID.wrap(hex"00");
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolver.selector, address(0)));
        registry.registerModule(invalidUID, address(newModule), "");

        invalidUID = ResolverUID.wrap("1");
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolver.selector, address(0)));
        registry.registerModule(invalidUID, address(newModule), "");
    }

    function test_WhenRegisteringAModuleOnAValidResolverUID()
        external
        prankWithAccount(moduleDev1)
    {
        // It should register.

        MockModule newModule = new MockModule();
        registry.registerModule(defaultResolverUID, address(newModule), "");
    }

    function test_WhenRegisteringAModuleOnAInValidResolverUID()
        external
        prankWithAccount(moduleDev1)
    {
        // It should revert

        MockModule newModule = new MockModule();
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolver.selector, address(0)));
        registry.registerModule(ResolverUID.wrap(bytes32("foobar")), address(newModule), "");
    }

    function test_WhenRegisteringTwoModulesWithTheSameBytecode()
        external
        prankWithAccount(moduleDev1)
    {
        MockModule newModule = new MockModule();
        // It should revert.
        registry.registerModule(defaultResolverUID, address(newModule), "");

        vm.expectRevert(
            abi.encodeWithSelector(IRegistry.AlreadyRegistered.selector, address(newModule))
        );
        registry.registerModule(defaultResolverUID, address(newModule), "");
    }
}
