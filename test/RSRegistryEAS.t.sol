// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EAS.t.sol";
import "../src/RSRegistryEAS.sol";

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title RSRegistryEASTest
/// @author zeroknots
contract RSRegistryEASTest is EASTest, EIP712 {
    RSRegistryEAS registry;

    address module = makeAddr("module1");

    constructor() EIP712("EAS", "0.28") { }

    function setUp() public override {
        super.setUp();
        registry = new RSRegistryEAS(address(eas));
    }

    function testRegister(address module) public returns (bytes32 schemaUid) {
        string memory schema = "bool secure";
        schemaUid = testRegisterSchema(schema, address(resolver));

        registry.register(module, schemaUid);
    }

    function testRegistryAttest() public returns (bytes32 schemaUid, bytes32 attestationId) {
        schemaUid = testRegister(module);

        uint256 authority1Priv = 1;
        address authority1 = vm.addr(authority1Priv);

        AttestationRequestData memory attData = AttestationRequestData({
            recipient: module,
            expirationTime: uint64(0),
            revocable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        bytes32 digest = registry.getAttestationDigest({
            attData: attData,
            schemaUid: schemaUid,
            attester: authority1
        });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authority1Priv, digest);
        EIP712Signature memory signature = EIP712Signature({ v: v, r: r, s: s });

        vm.prank(authority1);
        attestationId = registry.attest(module, attData, signature);
    }

    function testChainAttestation() public returns (bytes32 attestationId) {
        (bytes32 schemaUid, bytes32 originalAttestation) = testRegistryAttest();

        uint256 authority2Priv = 2;
        address authority2 = vm.addr(authority2Priv);

        AttestationRequestData memory attData = AttestationRequestData({
            recipient: module,
            expirationTime: uint64(0),
            revocable: true,
            refUID: originalAttestation,
            data: abi.encode(true),
            value: 0
        });

        bytes32 digest = registry.getAttestationDigest({
            attData: attData,
            schemaUid: schemaUid,
            attester: authority2
        });
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(authority2Priv, digest);
        EIP712Signature memory signature = EIP712Signature({ v: v, r: r, s: s });

        vm.prank(authority2);
        attestationId = registry.attest(module, attData, signature);
    }

    function testValidate() public {
        bytes32 chainedAttId = testChainAttestation();

        registry.validate(module, chainedAttId);
    }
}
