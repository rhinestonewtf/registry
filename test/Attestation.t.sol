// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/base/Attestation.sol";

import "./utils/ERC1271Attester.sol";

import "./utils/BaseTest.t.sol";

struct SampleAttestation {
    address[] dependencies;
    string comment;
    string url;
    bytes32 hash;
    uint256 severity;
}

/// @title AttestationTest
/// @author zeroknots
contract AttestationTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testCreateAttestation() public {
        instancel1.mockAttestation(defaultSchema1, auth1k, defaultModule1);
    }

    function testCreateLargeAttestation() public {
        SampleAttestation memory sample = SampleAttestation({
            dependencies: new address[](20),
            comment: "This is a test!!",
            url: "https://www.rhinestone.wtf",
            hash: bytes32(0),
            severity: 0
        });
        bytes memory data = abi.encode(sample);

        console2.log(data.length);

        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(0),
            data: data,
            value: 0
        });

        instancel1.newAttestation(defaultSchema1, auth1k, attData);
    }

    function testRevokeAttestation() public {
        testCreateAttestation();
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth1k);
        AttestationRecord memory attestation =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
    }

    function testReAttest() public {
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(0),
            data: "123",
            value: 0
        });
        instancel1.newAttestation(defaultSchema1, auth1k, attData);
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth1k);
        vm.warp(400);

        attData.data = "456";
        uint48 time = uint48(block.timestamp);
        instancel1.newAttestation(defaultSchema1, auth1k, attData);

        AttestationRecord memory attestation =
            instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));

        assertTrue(attestation.time == time);
    }

    function testAttestationNonExistingSchema() public {
        // TODO
        assertTrue(true);
    }

    function testERC1721Attestation() public {
        ERC1271Attester attester = new ERC1271Attester();

        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        bytes memory sig = EXPECTED_SIGNATURE;

        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attData,
            signature: sig,
            attester: address(attester)
        });

        instancel1.registry.attest(req);
    }

    function testMultiAttest() public {
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            subject: defaultModule1,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: anotherModule,
            moduleTypes: defaultModuleTypes,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = instancel1.signAttestation(defaultSchema1, auth1k, attArray);

        MultiDelegatedAttestationRequest[] memory reqs = new MultiDelegatedAttestationRequest[](1);
        MultiDelegatedAttestationRequest memory req1 = MultiDelegatedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            attester: vm.addr(auth1k),
            signatures: sigs
        });
        reqs[0] = req1;

        instancel1.registry.multiAttest(reqs);
    }
}
