// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "./Attestation.t.sol";
import "../src/interface/IQuery.sol";

import {
    ModuleTypes,
    ModuleType,
    MODULE_TYPE_EXECUTOR,
    MODULE_TYPE_VALIDATOR,
    MODULE_TYPE_HOOK
} from "src/DataTypes.sol";

/// @title RSRegistryTest
/// @author zeroknots, kopy-kat
contract QueryTest is AttestationTest {
    using RegistryTestLib for RegistryInstance;

    address immutable attester = address(this);

    function setUp() public virtual override {
        super.setUp();
    }

    function testCheckAttestation() public {
        testAttest();
        instance.registry.check(defaultModule1, attester);
    }

    function testCheckAttestation__RevertWhen__AttestationNotExistent() public {
        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instance.registry.check(defaultModule1, attester);
    }

    function testCheckAttestation__RevertWhen__Expired() public {
        vm.warp(100);
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth1k);
        vm.warp(200);
        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instance.registry.check(defaultModule1, attester);
    }

    function testCheckAttestation__RevertWhen__Revoked() public {
        testAttest();
        instance.revokeAttestation(defaultModule1, defaultSchema1, address(this));
        vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, attester));
        instance.registry.check(defaultModule1, attester);
    }

    function testCheckNAttestation() public {
        testAttest();
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth2k);
        address[] memory attesters = new address[](2);
        attesters[0] = attester;
        attesters[1] = vm.addr(auth2k);
        instance.registry.checkN(defaultModule1, attesters, 1);
    }

    function testCheckNAttestation__RevertWhen__ThresholdNotMet() public {
        testAttest();
        address[] memory attesters = new address[](2);
        attesters[0] = attester;
        attesters[1] = address(0x69);

        vm.expectRevert(IQuery.InsufficientAttestations.selector);
        instance.registry.checkN(defaultModule1, attesters, 2);
    }

    function testCheckNAttestation__RevertWhen__Expired() public {
        vm.warp(100);
        testAttest();
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth2k);
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(101),
            moduleTypes: ModuleTypes.wrap(3),
            data: abi.encode(false),
            value: 0
        });
        instance.newDelegatedAttestation(defaultSchema1, auth2k, attData);
        vm.warp(200);
        address[] memory attesters = new address[](2);
        attesters[0] = attester;
        attesters[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.AttestationNotFound.selector);
        instance.registry.checkN(defaultModule1, attesters, 1);
    }

    function testCheckNAttestation__RevertWhen__Revoked() public {
        testAttest();
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth2k);
        instance.delegatedRevokeAttestation(defaultModule1, defaultSchema1, auth2k);
        address[] memory attesters = new address[](2);
        attesters[0] = vm.addr(auth1k);
        attesters[1] = vm.addr(auth2k);

        vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, vm.addr(auth2k)));
        instance.registry.checkN(defaultModule1, attesters, 1);
    }

    function testCheckNAttestationUnsafe() public {
        testAttest();
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth2k);
        address[] memory attesters = new address[](2);
        attesters[0] = vm.addr(auth1k);
        attesters[1] = vm.addr(auth2k);
        instance.registry.checkNUnsafe(defaultModule1, attesters, 1);
    }

    function testCheckNAttestationUnsafe__RevertWhen__ThresholdNotMet() public {
        testAttest();
        address[] memory attesters = new address[](2);
        attesters[0] = vm.addr(auth1k);
        attesters[1] = vm.addr(auth2k);

        vm.expectRevert(IQuery.InsufficientAttestations.selector);
        instance.registry.checkNUnsafe(defaultModule1, attesters, 2);
    }

    function testCheckNAttestationUnsafe__Expired() public {
        vm.warp(100);
        testAttest();
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth1k);
        vm.warp(200);
        address[] memory attesters = new address[](2);
        attesters[0] = vm.addr(auth1k);
        attesters[1] = vm.addr(auth2k);

        instance.registry.checkNUnsafe(defaultModule1, attesters, 1);
    }

    function testCheckNAttestationUnsafe__Revoked() public {
        testAttest();
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth1k);
        instance.revokeAttestation(defaultModule1, defaultSchema1, address(this));
        address[] memory attesters = new address[](2);
        attesters[0] = vm.addr(auth1k);
        attesters[1] = vm.addr(auth2k);

        instance.registry.checkNUnsafe(defaultModule1, attesters, 1);
    }

    function testFindAttestation() public {
        testAttest();
        AttestationRecord memory attestation =
            instance.registry.findAttestation(defaultModule1, attester);
        assertEq(attestation.attester, attester);
    }

    function testFindAttestations() public {
        testAttest();
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, auth2k);

        address[] memory attesters = new address[](2);
        attesters[0] = attester;
        attesters[1] = vm.addr(auth2k);

        AttestationRecord[] memory attestations =
            instance.registry.findAttestations(defaultModule1, attesters);

        assertEq(attestations[0].attester, attesters[0]);
        assertEq(attestations[1].attester, attesters[1]);
    }

    function testCheckAttestationWithType() public {
        testAttest();
        instance.registry.check(defaultModule1, attester, MODULE_TYPE_EXECUTOR);
        instance.registry.check(defaultModule1, attester, MODULE_TYPE_VALIDATOR);
        vm.expectRevert();
        instance.registry.check(defaultModule1, attester, MODULE_TYPE_HOOK);
    }
}
