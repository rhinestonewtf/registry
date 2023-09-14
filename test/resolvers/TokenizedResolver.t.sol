// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/test/utils/mocks/MockERC20.sol";
import "../utils/BaseTest.t.sol";
import "../../src/resolver/examples/TokenizedResolver.sol";
import "../../src/resolver/examples/SimpleValidator.sol";

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
        console2.log("--------------------------------");
        bytes32 schema =
            instancel1.registerSchema("TokenizedResolver", ISchemaValidator(address(validator)));
        bytes32 resolverUID = instancel1.registerResolver(ISchemaResolver(address(resolver)));
        console.logBytes32(resolverUID);

        address module = instancel1.deployAndRegister(
            schema, type(MockModuleWithArgs).creationCode, abi.encode("asdfasdf")
        );

        AttestationRequestData memory attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0,
            resolverUID: resolverUID
        });
        console2.log("--------------------------------");

        vm.prank(vm.addr(auth1k));
        token.approve(address(resolver), 1000);
        instancel1.newAttestation(schema, auth1k, attData);
        console2.log("--------------------------------");
        assertEq(token.balanceOf(address(resolver)), 10);
    }
}
