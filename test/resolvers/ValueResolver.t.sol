// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../utils/BaseTest.t.sol";
import "../../src/external/examples/ValueResolver.sol";

contract ValueResolverTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    ValueResolver resolver;

    function setUp() public override {
        super.setUp();
        resolver = new ValueResolver(address(instance.registry));
    }

    function testValueResolver() public {
        SchemaUID schema =
            instance.registerSchema("TokenizedResolver", ISchemaValidator(address(0)));
        ResolverUID resolverUID = instance.registerResolver(IResolver(address(resolver)));

        address module = instance.deployAndRegister(
            resolverUID, type(MockModuleWithArgs).creationCode, abi.encode("asdfasdf")
        );

        AttestationRequestData memory attData = AttestationRequestData({
            subject: module,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 1 ether
        });

        bytes memory signature = RegistryTestLib.signAttestation(instance, schema, auth1k, attData);
        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schemaUID: schema,
            data: attData,
            signature: signature,
            attester: vm.addr(auth1k)
        });

        instance.registry.attest{ value: 1 ether }(req);
        assertTrue(address(resolver).balance > 0);
    }
}
