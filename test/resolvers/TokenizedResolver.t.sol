// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/src/test/utils/mocks/MockERC20.sol";
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
        resolver = new TokenizedResolver(
            address(instancel1.registry),
            address(token)
        );
        validator = new SimpleValidator();

        token.mint(vm.addr(auth1k), 10_000);
    }

    function testTokenizedResolver() public {
        SchemaUID schema =
            instancel1.registerSchema("TokenizedResolver", ISchemaValidator(address(validator)));
        ResolverUID resolverUID = instancel1.registerResolver(IResolver(address(resolver)));

        address module = instancel1.deployAndRegister(
            resolverUID, type(MockModuleWithArgs).creationCode, abi.encode("asdfasdf")
        );

        AttestationRequestData memory attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.prank(vm.addr(auth1k));
        token.approve(address(resolver), 1000);
        instancel1.newAttestation(schema, auth1k, attData);
        assertEq(token.balanceOf(address(resolver)), 10);
    }
}
