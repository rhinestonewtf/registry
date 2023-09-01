// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "./utils/BaseTest.t.sol";
/// @title RSRegistryTest
/// @author zeroknots

contract QueryTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    // function testQueryAttestation() public {
    //     bytes32 attestationUid = testCreateAttestation();
    //
    //     AttestationRecord memory attestation1 =
    //         instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
    // }

    function testCheck() public {
        instancel1.mockAttestation(defaultSchema1, auth1k, defaultModule1);

        instancel1.registry.checkID(defaultModule1, vm.addr(auth1k));
    }
}
