// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./RSAttestation.t.sol";

import { RSRegistry } from "../src/RSRegistry.sol";

/// @title RSRegistryTest
/// @author zeroknots
contract RSRegistryTest is RSAttestationTest {
    RSRegistry registry;

    function setUp() public virtual override {
        super.setUp();
        registry = new RSRegistry(
          Yaho(address(0)),
          Yaru(address(0)),
          address(0)
        );
        attestation = RSAttestation(address(registry));
        moduleRegistry = RSModuleRegistry(address(registry));
        schema = RSSchema(address(registry));
    }

    function testFindAttestation() public {
        (bytes32 schemaId, address moduleAddr, bytes32 attestationUid) = testCreateAttestation();

        registry.findAttestation(moduleAddr, auth1);
    }

    function testQueryChainedAttestation() public {
        (bytes32 schemaId, address moduleAddr, bytes32 attestationUid1, bytes32 attestationUid2) =
            testCreateChainedAttestation();

        Attestation memory attestation1 = registry.findAttestation(moduleAddr, auth1);
        assertEq(attestation1.uid, attestationUid1);
        Attestation memory attestation2 = registry.findAttestation(moduleAddr, auth2);
        assertEq(attestation2.uid, attestationUid2);

        address[] memory authorities = new address[](2);
        authorities[0] = auth1;
        authorities[1] = auth2;

        bool valid = registry.verifyWithRevert(moduleAddr, authorities, 2);
        assertTrue(valid);
    }

    function testQueryBrokenChainedAttestation() public {
        (bytes32 schemaId, address moduleAddr, bytes32 attestationUid1, bytes32 attestationUid2) =
            testCreateChainedAttestation();
        revokeFn(attestationUid1, schemaId, auth1, auth1k);

        Attestation memory attestation1 = registry.findAttestation(moduleAddr, auth1);
        assertEq(attestation1.uid, attestationUid1);
        Attestation memory attestation2 = registry.findAttestation(moduleAddr, auth2);
        assertEq(attestation2.uid, attestationUid2);

        address[] memory authorities = new address[](1);
        authorities[0] = auth2;

        vm.expectRevert(
            abi.encodeWithSelector(RSRegistry.RevokedAttestation.selector, attestation1.uid)
        );
        bool valid = registry.verifyWithRevert(moduleAddr, authorities, 1);
    }
}
