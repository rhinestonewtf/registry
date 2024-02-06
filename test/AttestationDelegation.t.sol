// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import {
    Attestation,
    IAttestation,
    InvalidSchema,
    NotFound,
    AccessDenied
} from "../src/base/Attestation.sol";
import { InvalidSignature, InvalidLength } from "../src/Common.sol";
import { ERC1271Attester, EXPECTED_SIGNATURE } from "./utils/ERC1271Attester.sol";

import {
    BaseTest,
    RegistryTestLib,
    RegistryInstance,
    console2,
    AttestationRequestData,
    SignedAttestationRequest,
    MockModuleWithArgs,
    ResolverUID,
    SchemaUID,
    ISchemaValidator
} from "./utils/BaseTest.t.sol";

import {
    AttestationRecord,
    MultiAttestationRequest,
    MultiSignedAttestationRequest,
    MultiRevocationRequest,
    RevocationRequestData,
    SignedRevocationRequest,
    MultiSignedRevocationRequest
} from "../src/DataTypes.sol";

struct SampleAttestation {
    address[] dependencies;
    string comment;
    string url;
    bytes32 hash;
    uint256 severity;
}

/// @title AttestationDelegationTest
/// @author kopy-kat
contract AttestationDelegationTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testAttest() public {
        instance.mockSignedAttestation(defaultSchema1, defaultModule1, auth1k);
    }

    function testAttest__RevertWhen__InvalidExpirationTime() public {
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(1),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidExpirationTime.selector));
        instance.newSignedAttestation(defaultSchema1, auth1k, attData);
    }

    function testAttest__RevertWhen__ZeroImplementation() public {
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: address(0x69),
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instance.newSignedAttestation(defaultSchema1, auth1k, attData);
    }

    function testAttest__RevertWhen__InvalidSchema() public {
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instance.newSignedAttestation(SchemaUID.wrap(0), auth1k, attData);
    }

    function testAttest__RevertWhen__ValidatorSaysInvalidAttestation() public {
        SchemaUID schemaUID = instance.registerSchema("", ISchemaValidator(falseSchemaValidator));
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instance.newSignedAttestation(schemaUID, auth1k, attData);
    }

    function testAttest__RevertWhen_InvalidSignature() public {
        SchemaUID schemaUID = instance.registerSchema("", ISchemaValidator(falseSchemaValidator));
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        bytes memory signature = "";
        SignedAttestationRequest memory req = SignedAttestationRequest({
            schemaUID: schemaUID,
            data: attData,
            signature: signature,
            attester: vm.addr(auth1k)
        });
        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        instance.registry.attest(req);
    }

    function testAttest__With__LargeAttestation() public {
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
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: data,
            value: 0
        });

        instance.newSignedAttestation(defaultSchema1, auth1k, attData);
    }

    function testMultiAttest() public {
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            moduleAddr: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = instance.signAttestation(defaultSchema1, auth1k, attArray);

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__InvalidSchema() public {
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            moduleAddr: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = instance.signAttestation(SchemaUID.wrap(0), auth1k, attArray);

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: SchemaUID.wrap(0),
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__ValidatorSaysInvalidAttestation() public {
        SchemaUID schemaUID = instance.registerSchema("", ISchemaValidator(falseSchemaValidator));
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            moduleAddr: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = instance.signAttestation(schemaUID, auth1k, attArray);

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: schemaUID,
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__InvalidExpirationTime() public {
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(1),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            moduleAddr: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = instance.signAttestation(defaultSchema1, auth1k, attArray);

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidExpirationTime.selector));
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__InvalidLength__DataLength() public {
        AttestationRequestData[] memory attArray = new AttestationRequestData[](0);

        bytes[] memory sigs = new bytes[](0);

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        vm.expectRevert();
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__InvalidLength__SignatureLength() public {
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(1),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            moduleAddr: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = new bytes[](0);

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(InvalidLength.selector));
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__InvalidSignature() public {
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(1),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            moduleAddr: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = new bytes[](2);
        sigs[0] = "";
        sigs[1] = "";

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__ZeroImplementation() public {
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            moduleAddr: address(0x69),
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            moduleAddr: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        bytes[] memory sigs = instance.signAttestation(defaultSchema1, auth1k, attArray);

        MultiSignedAttestationRequest[] memory reqs = new MultiSignedAttestationRequest[](1);
        MultiSignedAttestationRequest memory req1 = MultiSignedAttestationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            signatures: sigs,
            attester: vm.addr(auth1k)
        });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instance.registry.multiAttest(reqs);
    }

    function testRevoke() public {
        instance.mockSignedAttestation(defaultSchema1, defaultModule1, auth1k);
        instance.signedRevokeAttestation(defaultModule1, defaultSchema1, auth1k);

        AttestationRecord memory attestation =
            instance.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
    }

    function testRevoke__RevertWhen__InvalidSignature() public {
        address attester = vm.addr(auth1k);
        instance.mockSignedAttestation(defaultSchema1, defaultModule1, auth1k);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        SignedRevocationRequest memory req = SignedRevocationRequest({
            schemaUID: defaultSchema1,
            data: attData1,
            revoker: attester,
            signature: ""
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidSignature.selector));
        instance.registry.revoke(req);
    }

    function testRevoke__RevertWhen__AttestationNotFound() public {
        address attester = vm.addr(auth1k);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        bytes memory sig = instance.signRevocation(defaultSchema1, auth1k, attData1);

        SignedRevocationRequest memory req = SignedRevocationRequest({
            schemaUID: defaultSchema1,
            data: attData1,
            revoker: attester,
            signature: sig
        });

        vm.expectRevert(abi.encodeWithSelector(NotFound.selector));
        instance.registry.revoke(req);
    }

    function testRevoke__RevertWhen__InvalidSchema() public {
        address attester = vm.addr(auth1k);
        instance.mockSignedAttestation(defaultSchema1, defaultModule1, auth1k);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        bytes memory sig = instance.signRevocation(SchemaUID.wrap(0), auth1k, attData1);

        SignedRevocationRequest memory req = SignedRevocationRequest({
            schemaUID: SchemaUID.wrap(0),
            data: attData1,
            revoker: attester,
            signature: sig
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instance.registry.revoke(req);
    }

    function testRevoke__RevertWhen__AlreadyRevoked() public {
        instance.mockSignedAttestation(defaultSchema1, defaultModule1, auth1k);
        address attester = vm.addr(auth1k);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        bytes memory sig = instance.signRevocation(defaultSchema1, auth1k, attData1);

        SignedRevocationRequest memory req = SignedRevocationRequest({
            schemaUID: defaultSchema1,
            data: attData1,
            revoker: attester,
            signature: sig
        });
        instance.registry.revoke(req);

        bytes memory sig2 = instance.signRevocation(defaultSchema1, auth1k, attData1);

        SignedRevocationRequest memory req2 = SignedRevocationRequest({
            schemaUID: defaultSchema1,
            data: attData1,
            revoker: attester,
            signature: sig2
        });
        vm.expectRevert(abi.encodeWithSelector(IAttestation.AlreadyRevoked.selector));
        instance.registry.revoke(req2);
    }

    function testMultiRevoke() public {
        address attester = vm.addr(auth1k);
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instance.mockSignedAttestation(defaultSchema1, defaultModule1, auth1k);
        instance.mockSignedAttestation(defaultSchema1, anotherModule, auth1k);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ moduleAddr: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;
        bytes[] memory sigs = instance.signRevocation(defaultSchema1, auth1k, attArray);

        // RevocationRequestData[] memory attArray = new RevocationRequestData[](
        //     1
        // );
        // attArray[0] = attData1;

        // bytes[] memory sigs = instance.signRevocation(defaultSchema1, auth1k, attArray);

        MultiSignedRevocationRequest[] memory reqs = new MultiSignedRevocationRequest[](1);
        MultiSignedRevocationRequest memory req1 = MultiSignedRevocationRequest({
            schemaUID: defaultSchema1,
            data: attArray,
            revoker: attester,
            signatures: sigs
        });
        reqs[0] = req1;

        instance.registry.multiRevoke(reqs);

        AttestationRecord memory attestation =
            instance.registry.findAttestation(defaultModule1, attester);
        assertTrue(attestation.revocationTime != 0);

        AttestationRecord memory attestation2 =
            instance.registry.findAttestation(anotherModule, attester);
        assertTrue(attestation2.revocationTime != 0);
    }

    function testMultiRevoke__RevertWhen__InvalidSchema() public {
        address attester = address(this);
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instance.mockAttestation(defaultSchema1, defaultModule1);
        instance.mockAttestation(defaultSchema1, anotherModule);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ moduleAddr: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: SchemaUID.wrap(0), data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instance.registry.multiRevoke(reqs);
    }

    function testMultiRevoke__RevertWhen__AttestationNotFound() public {
        address attester = address(this);
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ moduleAddr: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(NotFound.selector));
        instance.registry.multiRevoke(reqs);
    }

    function testMultiRevoke__RevertWhen__NotOriginalAttester() public {
        address attester = address(this);
        address notAttester = makeAddr("notAttester");
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instance.mockAttestation(defaultSchema1, defaultModule1);
        instance.mockAttestation(defaultSchema1, anotherModule);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ moduleAddr: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        vm.startPrank(notAttester);
        vm.expectRevert(abi.encodeWithSelector(AccessDenied.selector));
        instance.registry.multiRevoke(reqs);
        vm.stopPrank();
    }

    function testMultiRevoke__RevertWhen__AlreadyRevoked() public {
        address attester = address(this);
        address anotherModule = instance.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instance.mockAttestation(defaultSchema1, defaultModule1);
        instance.mockAttestation(defaultSchema1, anotherModule);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ moduleAddr: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](2);
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        instance.registry.multiRevoke(reqs);

        vm.expectRevert(abi.encodeWithSelector(IAttestation.AlreadyRevoked.selector));
        instance.registry.multiRevoke(reqs);
    }
}
