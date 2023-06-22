// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "./RSAttestation.t.sol";
/// @title RSRegistryTest
/// @author zeroknots

contract RSQueryTest is RSAttestationTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testQueryAttestation() public {
        bytes32 attestationUid = testCreateAttestation();

        Attestation memory attestation1 =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
    }

    function testQueryChainedAttestation() public {
        (bytes32 attestationUid1, bytes32 attestationUid2) = testCreateChainedAttestation();

        Attestation memory attestation1 =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        Attestation memory attestation2 =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth2k));
    }

    function testQueryBrokenChainedAttestation() public {
        (bytes32 revokedAttestation, bytes32 chainedAttestation) = testBrokenChainAttestation();

        Attestation memory attestation1 =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        Attestation memory attestation2 =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth2k));
    }
}
