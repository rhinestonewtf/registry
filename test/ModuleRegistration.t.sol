// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";
import "./mocks/MockModule.sol";

contract ModuleRegistrationTest is BaseTest {
    function test_WhenDeployingViaRegistry() public prankWithAccount(moduleDev1) {
        bytes32 salt = keccak256(abi.encodePacked("ModuleRegistration", address(this)));

        bytes memory bytecode = type(MockModule).creationCode;

        address moduleAddr = registry.deployModule(salt, defaultResolverUID, bytecode, "", "");
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
        // It should revert.
        ResolverUID invalidUID = ResolverUID.wrap(hex"00");
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolver.selector, address(0)));
        registry.registerModule(invalidUID, address(module2), "");

        invalidUID = ResolverUID.wrap("1");
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolver.selector, address(0)));
        registry.registerModule(invalidUID, address(module2), "");
    }

    function test_WhenRegisteringAModuleOnAValidResolverUID()
        external
        prankWithAccount(moduleDev1)
    {
        // It should register.

        registry.registerModule(defaultResolverUID, address(module2), "");
    }

    function test_WhenRegisteringTwoModulesWithTheSameBytecode()
        external
        prankWithAccount(moduleDev1)
    {
        // It should revert.
        registry.registerModule(defaultResolverUID, address(module2), "");

        vm.expectRevert(
            abi.encodeWithSelector(IRegistry.AlreadyRegistered.selector, address(module2))
        );
        registry.registerModule(defaultResolverUID, address(module2), "");
    }
}
