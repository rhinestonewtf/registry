// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/test/utils/mocks/MockERC20.sol";
import "../utils/BaseTest.t.sol";
import "../../src/resolver/examples/TokenizedResolver.sol";

contract TokenizedResolverTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    MockERC20 token;
    TokenizedResolver resolver;

    function setUp() public override {
        super.setUp();
        token = new MockERC20("test", "test", 8);
        resolver = new TokenizedResolver(address(instancel1.registry), address(token));

        token.mint(vm.addr(auth1k), 10_000);
    }

    function testTokenizedResolver() public {
        bytes32 schema =
            instancel1.registerSchema("TokenizedResolver", ISchemaResolver(address(resolver)), true);

        address module = instancel1.deployAndRegister(
            schema, type(MockModuleWithArgs).creationCode, abi.encode("asdfasdf")
        );

        AttestationRequestData memory attData = AttestationRequestData({
            recipient: module,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        vm.prank(vm.addr(auth1k));
        token.approve(address(resolver), 1000);
        bytes32 attestationId = instancel1.newAttestation(schema, auth1k, attData);
        assertEq(token.balanceOf(address(resolver)), 10);
    }
}
