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

    HashiEnv hashiEnv;

    RegistryInstance instancel1;
    RegistryInstance instancel2;

    uint256 auth1k;
    uint256 auth2k;

    bytes32 defaultSchema1;
    bytes32 defaultSchema2;
    address defaultModule1;
    address defaultModule2;

    function setUp() public virtual {
        address hashiSigner = makeAddr("hashiSigner");
        hashiEnv = _setupHashi(hashiSigner);
        instancel1 = _setupInstance({
            name: "RegistryL1",
            yaho: hashiEnv.yaho,
            yaru: Yaru(address(0)),
            l1Registry: address(0)
        });
        instancel2 = _setupInstance({
            name: "RegistryL2",
            yaho: Yaho(address(0)),
            yaru: hashiEnv.yaru,
            l1Registry: address(instancel1.registry)
        });

        (, auth1k) = makeAddrAndKey("auth1");
        (, auth2k) = makeAddrAndKey("auth2");

        defaultSchema1 = instancel1.registerSchema("Test ABI", ISchemaValidator(address(0)));
        defaultSchema2 = instancel1.registerSchema("Test ABI2", ISchemaValidator(address(0)));

        instancel2.registerSchema("Test ABI", ISchemaValidator(address(0)));
        instancel2.registerSchema("Test ABI2", ISchemaValidator(address(0)));
        defaultModule1 = instancel1.deployAndRegister(
            defaultSchema1, type(MockModuleWithArgs).creationCode, abi.encode(1234)
        );
        defaultModule2 = instancel1.deployAndRegister(
            defaultSchema2, type(MockModuleWithArgs).creationCode, abi.encode(5678)
        );

        instancel2.registry.register({
            referrerUID: defaultSchema2,
            moduleAddress: defaultModule1,
            data: ""
        });
        instancel2.registry.register({
            referrerUID: defaultSchema2,
            moduleAddress: defaultModule2,
            data: ""
        });
    }
}
