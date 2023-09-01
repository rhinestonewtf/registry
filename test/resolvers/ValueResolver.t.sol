// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../utils/BaseTest.t.sol";
import "../../src/resolver/examples/ValueResolver.sol";

contract ValueResolverTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    ValueResolver resolver;

    function setUp() public override {
        super.setUp();
        resolver = new ValueResolver(address(instancel1.registry));
    }

    function testValueResolver() public {
        bytes32 schemaUID =
            instancel1.registerSchema("TokenizedResolver", ISchemaResolver(address(resolver)), true);

        address module = instancel1.deployAndRegister(
            schemaUID, type(MockModuleWithArgs).creationCode, abi.encode("asdfasdf")
        );

        AttestationRequestData memory attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 1 ether
        });

        EIP712Signature memory signature =
            RegistryTestLib.signAttestation(instancel1, schemaUID, auth1k, attData);
        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schemaUID: schemaUID,
            data: attData,
            signature: abi.encode(signature),
            attester: vm.addr(auth1k)
        });

        bytes32 attestationUid = instancel1.registry.attest{ value: 1 ether }(req);
        assertTrue(address(resolver).balance > 0);
    }
}
