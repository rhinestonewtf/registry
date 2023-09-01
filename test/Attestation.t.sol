// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/base/Attestation.sol";

import "./utils/ERC1271Attester.sol";

import "./utils/BaseTest.t.sol";

/// @title AttestationTest
/// @author zeroknots
contract AttestationTest is BaseTest {
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
        AttestationRecord memory attestation =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
    }

    function testCreateChainedAttestation()
        public
        returns (bytes32 attestationUid1, bytes32 attestationUid2)
    {
        attestationUid1 = testCreateAttestation();

        AttestationRequestData memory chainedAttestation = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: attestationUid1, //  <-- here is the reference
            data: abi.encode(true),
            value: 0
        });

        attestationUid2 = instancel1.newAttestation(defaultSchema1, auth2k, chainedAttestation);

        // revert if other schema is supplied
        vm.expectRevert(abi.encodeWithSelector(Attestation.InvalidAttestation.selector));
        instancel1.newAttestation(defaultSchema2, auth2k, chainedAttestation);

        AttestationRequestData memory referencingOtherModule = AttestationRequestData({
            subject: defaultModule2, // <-- here is the reference of the wrong module
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: attestationUid1, //  <-- here is the reference
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(Attestation.InvalidAttestation.selector));
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
        AttestationRecord memory attestation =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
        return (attestationUid1, attestationUid2);
    }

    function testAttestationNonExistingSchema() public {
        // TODO
        assertTrue(true);
    }

    function testERC1721Attestation() public {
        ERC1271Attester attester = new ERC1271Attester();

        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        EIP712Signature memory sig = EIP712Signature({ v: 27, r: "", s: "" });

        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attData,
            signature: abi.encode(sig),
            attester: address(attester)
        });

        instancel1.registry.attest(req);
    }

    function testMultiAttest() public {
        address anotherModule = instancel1.deployAndRegister(
            defaultSchema1, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: anotherModule,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        EIP712Signature[] memory sigs = instancel1.signAttestation(defaultSchema1, auth1k, attArray);

        bytes[] memory sigsBytes = new bytes[](sigs.length);
        for (uint256 index = 0; index < sigs.length; index++) {
            sigsBytes[index] = abi.encode(sigs[index]);
        }

        MultiDelegatedAttestationRequest[] memory reqs = new MultiDelegatedAttestationRequest[](1);
        MultiDelegatedAttestationRequest memory req1 = MultiDelegatedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            attester: vm.addr(auth1k),
            signatures: sigsBytes
        });
        reqs[0] = req1;

        instancel1.registry.multiAttest(reqs);
    }
}
