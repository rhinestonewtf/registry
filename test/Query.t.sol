// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "./Attestation.t.sol";
import "../src/interface/IQuery.sol";

/// @title RSRegistryTest
/// @author zeroknots

contract QueryTest is AttestationTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testQueryAttestation() public {
        bytes32 attestationUid = testCreateAttestation();

        AttestationRecord memory attestation1 =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
    }

    function testCheckAttestation() public {
        testCreateAttestation();
        instancel1.registry.check(defaultModule1, vm.addr(auth1k));
    }

    function testCheckAttestation__RevertWhen__Unlisted() public {
        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instancel1.registry.check(defaultModule1, vm.addr(auth1k));
    }

    function testCheckAttestation__RevertWhen__Expired() public {
        vm.warp(100);
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0,
            schemaUID: defaultSchema1
        });
        bytes32 attestationUid = instancel1.mockAttestation(defaultSchema1, auth1k, attData);
        vm.warp(200);
        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instancel1.registry.check(defaultModule1, vm.addr(auth1k));
    }

    function testCheckAttestation__RevertWhen__Revoked() public {
        bytes32 attestationUid = testCreateAttestation();
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth1k);
        vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, attestationUid));
        instancel1.registry.check(defaultModule1, vm.addr(auth1k));
    }

    function testVerifyAttestation() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0,
            schemaUID: defaultSchema1
        });
        bytes32 attestationUid = instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);
        instancel1.registry.verify(defaultModule1, authorities, 1);
    }

    function testVerifyAttestation__RevertWhen__ThresholdNotMet() public {
        testCreateAttestation();
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.InsufficientAttestations.selector);
        instancel1.registry.verify(defaultModule1, authorities, 2);
    }

    function testVerifyAttestation__RevertWhen__Expired() public {
        vm.warp(100);
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0,
            schemaUID: defaultSchema1
        });
        bytes32 attestationUid = instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        vm.warp(200);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instancel1.registry.verify(defaultModule1, authorities, 1);
    }

    function testVerifyAttestation__RevertWhen__Revoked() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0,
            schemaUID: defaultSchema1
        });
        bytes32 attestationUid = instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth2k);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, attestationUid));
        instancel1.registry.verify(defaultModule1, authorities, 1);
    }

    function testVerifyAttestationUnsafe() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0,
            schemaUID: defaultSchema1
        });
        bytes32 attestationUid = instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);
        instancel1.registry.verifyUnsafe(defaultModule1, authorities, 1);
    }

    function testVerifyAttestationUnsafe__RevertWhen__ThresholdNotMet() public {
        testCreateAttestation();
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.InsufficientAttestations.selector);
        instancel1.registry.verifyUnsafe(defaultModule1, authorities, 2);
    }

    function testVerifyAttestationUnsafe__Expired() public {
        vm.warp(100);
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0,
            schemaUID: defaultSchema1
        });
        bytes32 attestationUid = instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        vm.warp(200);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        instancel1.registry.verifyUnsafe(defaultModule1, authorities, 1);
    }

    function testVerifyAttestationUnsafe__Revoked() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0,
            schemaUID: defaultSchema1
        });
        bytes32 attestationUid = instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth2k);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        instancel1.registry.verifyUnsafe(defaultModule1, authorities, 1);
    }
}
