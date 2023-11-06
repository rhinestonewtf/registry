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
        testCreateAttestation();

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
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(101),
            data: abi.encode(true),
            value: 0
        });
        instancel1.mockAttestation(defaultSchema1, auth1k, attData);
        vm.warp(200);
        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instancel1.registry.check(defaultModule1, vm.addr(auth1k));
    }

    function testCheckAttestation__RevertWhen__Revoked() public {
        testCreateAttestation();
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth1k);
        vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, vm.addr(auth1k)));
        instancel1.registry.check(defaultModule1, vm.addr(auth1k));
    }

    function testCheckNAttestation() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(101),
            data: abi.encode(true),
            value: 0
        });
        instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);
        instancel1.registry.checkN(defaultModule1, authorities, 1);
    }

    function testCheckNAttestation__RevertWhen__ThresholdNotMet() public {
        testCreateAttestation();
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.InsufficientAttestations.selector);
        instancel1.registry.checkN(defaultModule1, authorities, 2);
    }

    function testCheckNAttestation__RevertWhen__Expired() public {
        vm.warp(100);
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(101),
            data: abi.encode(true),
            value: 0
        });
        instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        vm.warp(200);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instancel1.registry.checkN(defaultModule1, authorities, 1);
    }

    function testCheckNAttestation__RevertWhen__Revoked() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(101),
            data: abi.encode(true),
            value: 0
        });
        instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth2k);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, vm.addr(auth2k)));
        instancel1.registry.checkN(defaultModule1, authorities, 1);
    }

    function testCheckNAttestationUnsafe() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(101),
            data: abi.encode(true),
            value: 0
        });
        instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);
        instancel1.registry.checkNUnsafe(defaultModule1, authorities, 1);
    }

    function testCheckNAttestationUnsafe__RevertWhen__ThresholdNotMet() public {
        testCreateAttestation();
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.InsufficientAttestations.selector);
        instancel1.registry.checkNUnsafe(defaultModule1, authorities, 2);
    }

    function testCheckNAttestationUnsafe__Expired() public {
        vm.warp(100);
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(101),
            data: abi.encode(true),
            value: 0
        });
        instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        vm.warp(200);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        instancel1.registry.checkNUnsafe(defaultModule1, authorities, 1);
    }

    function testCheckNAttestationUnsafe__Revoked() public {
        testCreateAttestation();
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(101),
            data: abi.encode(true),
            value: 0
        });
        instancel1.mockAttestation(defaultSchema1, auth2k, attData);
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth2k);
        address[] memory authorities = new address[](2);
        authorities[0] = vm.addr(auth1k);
        authorities[1] = vm.addr(auth2k);

        instancel1.registry.checkNUnsafe(defaultModule1, authorities, 1);
    }

    function testCheckAttestationCheckType() public {
        testCreateAttestation();

        for (uint8 i = 0; i < 255; i++) {
            if (i == 3 || i == 5 || i == 15) {
                instancel1.registry.check(defaultModule1, vm.addr(auth1k), i);
            } else {
                vm.expectRevert();
                instancel1.registry.check(defaultModule1, vm.addr(auth1k), i);
            }
        }
    }
}
