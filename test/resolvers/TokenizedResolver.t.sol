// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../RSRegistry.t.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "../../src/resolver/examples/TokenizedResolver.sol";

contract TokenizedResolverTest is RSRegistryTest {
    MockERC20 token;
    TokenizedResolver resolver;

    function setUp() public override {
        super.setUp();
        token = new MockERC20("test", "test", 8);
        resolver = new TokenizedResolver(address(registry), address(token));
        token.mint(auth2, 10_000);
    }

    function testTokenizedResolver() public {
        (bytes32 schemaId, address moduleAddr, bytes32 attestationUid) = testCreateAttestation();
        registry.setResolver(schemaId, ISchemaResolver(address(resolver)));

        AttestationRequestData memory attData = AttestationRequestData({
            recipient: moduleAddr,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        bytes32 digest = attestation.getAttestationDigest({
            attData: attData,
            schemaUid: schemaId,
            attester: auth2
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(auth2k, digest);
        EIP712Signature memory signature = EIP712Signature({ v: v, r: r, s: s });

        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schema: schemaId,
            data: attData,
            signature: signature,
            attester: auth2
        });

        vm.expectRevert();
        attestationUid = attestation.attest(req);

        vm.prank(auth2);
        token.approve(address(resolver), 100);
        attestationUid = attestation.attest(req);

        registry.findAttestation(moduleAddr, auth2);
    }
}
