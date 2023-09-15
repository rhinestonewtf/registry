// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../utils/BaseTest.t.sol";
import "../../src/external/examples/ValueResolver.sol";

contract ValueResolverTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    ValueResolver resolver;

    function setUp() public override {
        super.setUp();
        resolver = new ValueResolver(address(instancel1.registry));
    }

    function testValueResolver() public {
        SchemaUID schema =
            instancel1.registerSchema("TokenizedResolver", ISchemaValidator(address(0)));
        ResolverUID resolverUID = instancel1.registerResolver(IResolver(address(resolver)));

        address module = instancel1.deployAndRegister(
            resolverUID, type(MockModuleWithArgs).creationCode, abi.encode("asdfasdf")
        );

        AttestationRequestData memory attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 1 ether
        });

        bytes memory signature =
            RegistryTestLib.signAttestation(instancel1, schema, auth1k, attData);
        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schemaUID: schema,
            data: attData,
            signature: signature,
            attester: vm.addr(auth1k)
        });

        instancel1.registry.attest{ value: 1 ether }(req);
        assertTrue(address(resolver).balance > 0);
    }
}
