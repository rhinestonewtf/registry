// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./BaseUtils.sol";
import "../../src/resolver/ISchemaResolver.sol";

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

    bytes32 defaultSchema1;
    bytes32 defaultSchema2;
    address defaultModule1;
    address defaultModule2;

    function setUp() public virtual {
        instancel1 = _setupInstance("RegistryL1");
        instancel2 = _setupInstance("RegistryL2");

        (, auth1k) = makeAddrAndKey("auth1");
        (, auth2k) = makeAddrAndKey("auth2");

        defaultSchema1 = instancel1.registerSchema("Test ABI", ISchemaResolver(address(0)), true);

        defaultSchema2 = instancel1.registerSchema("Test ABI2", ISchemaResolver(address(0)), true);
        defaultModule1 = instancel1.deployAndRegister(
            defaultSchema1, type(MockModuleWithArgs).creationCode, abi.encode(1234)
        );
        defaultModule2 = instancel1.deployAndRegister(
            defaultSchema1, type(MockModuleWithArgs).creationCode, abi.encode(5678)
        );
    }
}
