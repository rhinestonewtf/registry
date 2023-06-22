// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/base/RSAttestation.sol";

import "./utils/BaseTest.t.sol";

/// @title RSAttestationTest
/// @author zeroknots
contract RSAttestationTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testCreateAttestation() public returns (bytes32 attestationUid) {
        attestationUid = instancel1.mockAttestation(defaultSchema1, auth1k, defaultModule1);
        assertTrue(attestationUid != bytes32(0));
    }

    function testRevokeAttestation() public {
        bytes32 attestationUid = testCreateAttestation();
        instancel1.revokeAttestation(attestationUid, defaultSchema1, auth1k);
        Attestation memory attestation =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
    }

    function testCreateChainedAttestation()
        public
        returns (bytes32 attestationUid1, bytes32 attestationUid2)
    {
        attestationUid1 = testCreateAttestation();

        AttestationRequestData memory chainedAttestation = AttestationRequestData({
            recipient: defaultModule1,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: attestationUid1, //  <-- here is the reference
            data: abi.encode(true),
            value: 0
        });

        attestationUid2 = instancel1.newAttestation(defaultSchema1, auth2k, chainedAttestation);

        // revert if other schema is supplied
        vm.expectRevert(abi.encodeWithSelector(RSAttestation.InvalidAttestation.selector));
        instancel1.newAttestation(defaultSchema2, auth2k, chainedAttestation);

        AttestationRequestData memory referencingOtherModule = AttestationRequestData({
            recipient: defaultModule2, // <-- here is the reference of the wrong module
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: attestationUid1, //  <-- here is the reference
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(RSAttestation.InvalidAttestation.selector));
        instancel1.newAttestation(defaultSchema1, auth2k, referencingOtherModule);

        // this should work
        instancel1.newAttestation(defaultSchema2, auth2k, referencingOtherModule);
    }

    function testBrokenChainAttestation()
        public
        returns (bytes32 revokedAttestation, bytes32 chainedAttestation)
    {
        (bytes32 attestationUid1, bytes32 attestationUid2) = testCreateChainedAttestation();
        instancel1.revokeAttestation(attestationUid1, defaultSchema1, auth1k);
        Attestation memory attestation =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
        return (attestationUid1, attestationUid2);
    }
}
