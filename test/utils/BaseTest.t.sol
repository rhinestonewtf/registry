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

contract FalseSchemaValidator is ISchemaValidator {
    function validateSchema(AttestationRequestData calldata attestation)
        external
        view
        returns (bool)
    {
        return false;
    }

    /**
     * @notice Validates an array of attestation requests.
     */
    function validateSchema(AttestationRequestData[] calldata attestations)
        external
        view
        returns (bool)
    {
        return false;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) { }
}

contract BaseTest is Test, RegistryTestTools {
    using RegistryTestLib for RegistryInstance;

    RegistryInstance instance;

    uint256 auth1k;
    uint256 auth2k;

    uint8[] defaultModuleTypesEncoded;

    SchemaUID defaultSchema1;
    SchemaUID defaultSchema2;
    ResolverUID defaultResolver;
    address defaultModule1;
    address defaultModule2;

    DebugResolver debugResolver;

    address falseSchemaValidator;

    function setUp() public virtual {
        defaultModuleTypesEncoded = new uint8[](2);
        defaultModuleTypesEncoded[0] = 2;
        defaultModuleTypesEncoded[1] = 3;
        instance = _setupInstance({ name: "RegistryL1", salt: 0 });
        (, auth1k) = makeAddrAndKey("auth1");
        (, auth2k) = makeAddrAndKey("auth2");

        falseSchemaValidator = address(new FalseSchemaValidator());

        defaultSchema1 = instance.registerSchema("Test ABI", ISchemaValidator(address(0)));
        defaultSchema2 = instance.registerSchema("Test ABI2", ISchemaValidator(address(0)));
        debugResolver = new DebugResolver(address(instance.registry));
        defaultResolver = instance.registerResolver(IResolver(address(debugResolver)));

        defaultModule1 = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1234)
        );
        defaultModule2 = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(5678)
        );
    }
}
