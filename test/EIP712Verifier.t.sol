// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseTest, RegistryTestLib, RegistryInstance } from "./utils/BaseTest.t.sol";
import {
    EIP712Verifier,
    DelegatedAttestationRequest,
    DelegatedRevocationRequest,
    SchemaUID,
    AttestationRequestData,
    RevocationRequestData,
    InvalidSignature
} from "../src/base/EIP712Verifier.sol";

import { console2 } from "forge-std/console2.sol";

struct SampleAttestation {
    address[] dependencies;
    string comment;
    string url;
    bytes32 hash;
    uint256 severity;
}

contract EIP712VerifierInstance is EIP712Verifier {
    function verifyAttest(DelegatedAttestationRequest memory request) public {
        _verifyAttest(request);
    }

    function verifyRevoke(DelegatedRevocationRequest memory request) public {
        _verifyRevoke(request);
    }

    function hashTypedData(bytes32 structHash) public view virtual returns (bytes32 digest) {
        digest = super._hashTypedData(structHash);
    }
}

/// @title EIP712VerifierTest
/// @author kopy-kat
contract EIP712VerifierTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    EIP712VerifierInstance verifier;

    function setUp() public virtual override {
        super.setUp();

        verifier = new EIP712VerifierInstance();
    }

    function testGetNonce() public {
        address account = makeAddr("account");
        uint256 nonce = verifier.getNonce(account);
        assertEq(nonce, 0);

        // Since _newNonce is private, we verify an Attestation which increments the nonce
        testVerifyAttest();
        nonce = verifier.getNonce(account);
        assertEq(nonce, 1);
    }

    function testGetAttestationDigest() public {
        address account = makeAddr("account");
        SchemaUID schemaUID = SchemaUID.wrap(0);
        uint256 nonce = verifier.getNonce(account) + 1;

        AttestationRequestData memory attData = AttestationRequestData({
            subject: address(0),
            expirationTime: uint48(0),
            value: 0,
            data: ""
        });

        bytes32 digest1 = verifier.getAttestationDigest(attData, schemaUID, account);
        bytes32 digest2 = verifier.getAttestationDigest(attData, schemaUID, nonce);
        assertEq(digest1, digest2);

        bytes32 digest3 = verifier.hashTypedData(
            keccak256(
                abi.encode(
                    verifier.getAttestTypeHash(),
                    block.chainid,
                    schemaUID,
                    attData.subject,
                    attData.expirationTime,
                    keccak256(attData.data),
                    nonce
                )
            )
        );

        assertEq(digest1, digest3);
    }

    function testVerifyAttest() public {
        SchemaUID schemaUID = SchemaUID.wrap(0);
        AttestationRequestData memory attData = AttestationRequestData({
            subject: address(0x69),
            expirationTime: uint48(0),
            value: 0,
            data: abi.encode(true)
        });
        bytes memory signature = instance.signAttestation(schemaUID, auth1k, attData);
        DelegatedAttestationRequest memory request = DelegatedAttestationRequest({
            schemaUID: schemaUID,
            data: attData,
            attester: vm.addr(auth1k),
            signature: signature
        });

        verifier.verifyAttest(request);
    }

    function testVerifyAttest__RevertWhen__InvalidSignature() public {
        address attester = makeAddr("attester");
        AttestationRequestData memory attData = AttestationRequestData({
            subject: address(0),
            expirationTime: uint48(0),
            value: 0,
            data: ""
        });
        DelegatedAttestationRequest memory request = DelegatedAttestationRequest({
            schemaUID: SchemaUID.wrap(0),
            data: attData,
            attester: attester,
            signature: ""
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        verifier.verifyAttest(request);
    }

    function testGetRevocationDigest() public {
        address account = makeAddr("account");
        SchemaUID schemaUID = SchemaUID.wrap(0);
        uint256 nonce = verifier.getNonce(account) + 1;

        RevocationRequestData memory revData =
            RevocationRequestData({ subject: address(0), attester: account, value: 0 });

        bytes32 digest1 = verifier.getRevocationDigest(revData, schemaUID, account);
        bytes32 digest2 = verifier.getRevocationDigest(revData, schemaUID, nonce);
        assertEq(digest1, digest2);

        bytes32 digest3 = verifier.hashTypedData(
            keccak256(
                abi.encode(
                    verifier.getRevokeTypeHash(),
                    block.chainid,
                    schemaUID,
                    revData.subject,
                    account,
                    nonce
                )
            )
        );

        assertEq(digest1, digest3);
    }

    function testVerifyRevoke() public {
        address revoker = vm.addr(auth1k);
        SchemaUID schemaUID = SchemaUID.wrap(0);
        RevocationRequestData memory revData =
            RevocationRequestData({ subject: address(0), attester: revoker, value: 0 });

        bytes memory signature = instance.signRevocation(schemaUID, auth1k, revData);
        DelegatedRevocationRequest memory request = DelegatedRevocationRequest({
            schemaUID: schemaUID,
            data: revData,
            revoker: revoker,
            signature: signature
        });

        verifier.verifyRevoke(request);
    }
}
