// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "./Attestation.t.sol";
/// @title RSRegistryTest
/// @author zeroknots

contract QueryTest is AttestationTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function testQueryAttestation() public {
        bytes32 attestationUid = testCreateAttestation();

        AttestationRecord memory attestation1 =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
    }
}
