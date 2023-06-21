// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./RSAttestation.t.sol";

import { RSRegistry } from "../src/RSRegistry.sol";

/// @title RSRegistryTest
/// @author zeroknots
contract RSRegistryTest is RSAttestationTest {
    RSRegistry registry;

    function setUp() public override {
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
}
