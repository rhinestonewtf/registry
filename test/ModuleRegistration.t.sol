// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";
import "./mocks/MockModule.sol";

contract Factory {
    address returnAddress;

    function setReturnAddress(address _addr) public {
        returnAddress = _addr;
    }

    function deployFn() external returns (address) {
        return returnAddress;
    }
}

contract ModuleRegistrationTest is BaseTest {
    function test_WhenDeployingViaRegistry() public prankWithAccount(moduleDev1) {
        bytes32 salt = bytes32(abi.encodePacked(address(moduleDev1.addr), bytes12(0)));

        bytes memory bytecode = type(MockModule).creationCode;

        address moduleAddr = registry.deployModule(salt, defaultResolverUID, bytecode, "", "");
        ModuleRecord memory record = registry.findModule(moduleAddr);
        assertTrue(record.resolverUID == defaultResolverUID);
    }

    function test_WhenDeployingViaRegistryWithArgs() public prankWithAccount(moduleDev1) {
        bytes32 salt = bytes32(abi.encodePacked(address(moduleDev1.addr), bytes12(0)));

        bytes memory bytecode = type(MockModuleWithArgs).creationCode;
        bytes memory initCode = abi.encodePacked(bytecode, abi.encode(313_131));

        address moduleAddr = registry.deployModule(salt, defaultResolverUID, initCode, "", "");

        address moduleAddrCalc = registry.calcModuleAddress(salt, initCode);
        assertTrue(moduleAddr == moduleAddrCalc);
    }

    function test_WhenRegisteringAModuleOnAnInvalidResolverUID() external prankWithAccount(moduleDev1) {
        MockModule newModule = new MockModule();
        // It should revert.
        ResolverUID invalidUID = ResolverUID.wrap(hex"00");

        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolverUID.selector, invalidUID));
        registry.registerModule(invalidUID, address(newModule), "");

        invalidUID = ResolverUID.wrap("1");
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolverUID.selector, invalidUID));
        registry.registerModule(invalidUID, address(newModule), "");

    }

    function test_WhenRegisteringAModuleOnAValidResolverUID() external prankWithAccount(moduleDev1) {
        // It should register.

        MockModule newModule = new MockModule();
        registry.registerModule(defaultResolverUID, address(newModule), "", "");
    }

    function test_WhenRegisteringAModuleOnAInValidResolverUID() external prankWithAccount(moduleDev1) {
        // It should revert

        MockModule newModule = new MockModule();

        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidResolverUID.selector, ResolverUID.wrap(bytes32("foobar"))));
        registry.registerModule(ResolverUID.wrap(bytes32("foobar")), address(newModule), "");

    }

    function test_WhenRegisteringTwoModulesWithTheSameBytecode() external prankWithAccount(moduleDev1) {
        MockModule newModule = new MockModule();
        // It should revert.
        registry.registerModule(defaultResolverUID, address(newModule), "", "");

        vm.expectRevert(abi.encodeWithSelector(IRegistry.AlreadyRegistered.selector, address(newModule)));
        registry.registerModule(defaultResolverUID, address(newModule), "", "");
    }

    function test_WhenRegisteringViaFactory() public {
        Factory factory = new Factory();

        bytes32 salt = keccak256(abi.encodePacked("ModuleRegistration", address(this)));

        factory.setReturnAddress(address(0));
        vm.expectRevert();
        registry.deployViaFactory(address(factory), abi.encodeCall(factory.deployFn, ()), "", defaultResolverUID, "");

        factory.setReturnAddress(address(1));
        vm.expectRevert();

        registry.deployViaFactory(address(factory), abi.encodeCall(factory.deployFn, ()), "", defaultResolverUID, "");

        MockModule newModule = new MockModule();
        factory.setReturnAddress(address(newModule));
        registry.deployViaFactory(address(factory), abi.encodeCall(factory.deployFn, ()), "", defaultResolverUID, "");
    }

    function test_WhenUsingInvalidFactory() public {
        vm.expectRevert();
        registry.deployViaFactory(address(0), "", "", defaultResolverUID, "");
    }

    function test_WhenUsingRegistryASFactory() public {
        vm.expectRevert();
        registry.deployViaFactory(address(registry), "", "", defaultResolverUID, "");
    }
}
