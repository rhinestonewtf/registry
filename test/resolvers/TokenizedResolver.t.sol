// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/test/utils/mocks/MockERC20.sol";
import "../utils/BaseTest.t.sol";
import "../../src/external/examples/TokenizedResolver.sol";
import "../../src/external/examples/SimpleValidator.sol";

contract TokenizedResolverTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    MockERC20 token;
    TokenizedResolver resolver;
    SimpleValidator validator;

    function setUp() public override {
        super.setUp();
        token = new MockERC20("test", "test", 8);
        resolver = new TokenizedResolver(address(instance.registry), address(token));
        validator = new SimpleValidator();

        token.mint(address(this), 10_000);
    }

    function testTokenizedResolver() public {
        SchemaUID schema =
            instance.registerSchema("TokenizedResolver", ISchemaValidator(address(validator)));
        ResolverUID resolverUID = instance.registerResolver(IResolver(address(resolver)));

        address module = instance.deployAndRegister(
            resolverUID, type(MockModuleWithArgs).creationCode, abi.encode("asdfasdf")
        );

        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: module,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.prank(address(this));
        token.approve(address(resolver), 1000);
        instance.newAttestation(schema, attData);
        assertEq(token.balanceOf(address(resolver)), 10);
    }
}
