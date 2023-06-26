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
}
