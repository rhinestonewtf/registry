// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./RSModuleRegistry.t.sol";
import "../src/RSAttestation.sol";

// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";
/// @title RSAttestationTest
/// @author zeroknots

contract RSAttestationTest is RSModuleRegistryTest {
    RSAttestation attestation;

    address auth1;
    uint256 auth1k;

    address auth2;
    uint256 auth2k;

    function setUp() public override {
        super.setUp();
        attestation = new RSAttestation(
        Yaho(address(0)),
        Yaru(address(0)),
        address(0)
      );
        moduleRegistry = RSModuleRegistry(address(attestation));
        schema = RSSchema(address(attestation));
        (auth1, auth1k) = makeAddrAndKey("auth1");
        (auth2, auth2k) = makeAddrAndKey("auth2");
    }

    function testCreateAttestation()
        public
        returns (bytes32 schemaId, address moduleAddr, bytes32 attestationUid)
    {
        schemaId = registerSchema(
            RSSchema(address(attestation)), "test2", ISchemaResolver(address(0)), true
        );

        moduleAddr = attestation.deploy({
            code: type(MockModule).creationCode,
            deployParams: abi.encode(1234),
            salt: 0,
            data: "",
            schemaId: schemaId
        });

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
            attester: auth1
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(auth1k, digest);
        EIP712Signature memory signature = EIP712Signature({ v: v, r: r, s: s });

        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schema: schemaId,
            data: attData,
            signature: signature,
            attester: auth1
        });

        attestationUid = attestation.attest(req);
        assertTrue(attestationUid != bytes32(0));
    }

    function testCreateChainedAttestation() public {
        (bytes32 schemaId, address moduleAddr, bytes32 attestationUid) = testCreateAttestation();

        AttestationRequestData memory attData = AttestationRequestData({
            recipient: moduleAddr,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: attestationUid, //  <-- here is the reference
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

        attestationUid = attestation.attest(req);
        assertTrue(attestationUid != bytes32(0));
    }
}
