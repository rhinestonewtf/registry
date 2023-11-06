// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./BaseUtils.sol";
import "../../src/external/IResolver.sol";
import "../../src/external/examples/DebugResolver.sol";

contract MockModuleWithArgs {
    uint256 value;

    constructor(uint256 _value) {
        value = _value;
    }

    function readValue() public view returns (uint256) {
        return value;
    }
}

contract MockModule {
    uint256 value;

    function readValue() public view returns (uint256) {
        return value;
    }
}

contract BaseTest is Test, RegistryTestTools {
    using RegistryTestLib for RegistryInstance;

    RegistryInstance instancel1;
    RegistryInstance instancel2;

    uint256 auth1k;
    uint256 auth2k;

    uint8[] defaultModuleTypes;

    SchemaUID defaultSchema1;
    SchemaUID defaultSchema2;
    ResolverUID defaultResolver;
    address defaultModule1;
    address defaultModule2;

    function setUp() public virtual {
        defaultModuleTypes = new uint8[](1);
        defaultModuleTypes[0] = 3;
        instancel1 = _setupInstance({ name: "RegistryL1", salt: 0 });
        (, auth1k) = makeAddrAndKey("auth1");
        (, auth2k) = makeAddrAndKey("auth2");

        defaultSchema1 = instancel1.registerSchema("Test ABI", ISchemaValidator(address(0)));
        defaultSchema2 = instancel1.registerSchema("Test ABI2", ISchemaValidator(address(0)));
        DebugResolver debugResolver = new DebugResolver(address(instancel1.registry));
        defaultResolver = instancel1.registerResolver(IResolver(address(debugResolver)));

        defaultModule1 = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1234)
        );
        defaultModule2 = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(5678)
        );
    }
}
