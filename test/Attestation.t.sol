// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { IAttestation, InvalidSchema, NotFound, AccessDenied } from "../src/base/Attestation.sol";

import { ERC1271Attester, EXPECTED_SIGNATURE } from "./utils/ERC1271Attester.sol";

import {
    BaseTest,
    RegistryTestLib,
    RegistryInstance,
    console2,
    AttestationRequestData,
    MockModuleWithArgs,
    SchemaUID,
    ISchemaValidator
} from "./utils/BaseTest.t.sol";

import {
    AttestationRecord,
    MultiSignedAttestationRequest,
    MultiAttestationRequest,
    MultiRevocationRequest,
    RevocationRequestData,
    RevocationRequest
} from "../src/DataTypes.sol";

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

    function testAttest() public {
        instance.mockAttestation(defaultSchema1, defaultModule1);
    }

    function testAttest__RevertWhen__InvalidExpirationTime() public {
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(1),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidExpirationTime.selector));
        instance.newAttestation(defaultSchema1, attData);
    }

    function testAttest__RevertWhen__ZeroImplementation() public {
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: address(0x69),
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instance.newAttestation(defaultSchema1, attData);
    }

    function testAttest__RevertWhen__InvalidSchema() public {
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instance.newAttestation(SchemaUID.wrap(0), attData);
    }

    function testAttest__RevertWhen__ValidatorSaysInvalidAttestation() public {
        SchemaUID schemaId = instance.registerSchema("", ISchemaValidator(falseSchemaValidator));
        AttestationRequestData memory attData = AttestationRequestData({
            moduleAddr: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instance.newAttestation(schemaId, attData);
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

        instance.newAttestation(defaultSchema1, attData);
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

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: defaultSchema1, data: attArray });
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

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: SchemaUID.wrap(0), data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__ValidatorSaysInvalidAttestation() public {
        SchemaUID schemaId = instance.registerSchema("", ISchemaValidator(falseSchemaValidator));
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

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: schemaId, data: attArray });
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

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidExpirationTime.selector));
        instance.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__ZeroImplementation() public {
        SchemaUID schemaId = instance.registerSchema("", ISchemaValidator(falseSchemaValidator));
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

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: schemaId, data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instance.registry.multiAttest(reqs);
    }

    function testRevoke() public {
        address attester = address(this);
        instance.mockAttestation(defaultSchema1, defaultModule1);
        instance.revokeAttestation(defaultModule1, defaultSchema1, attester);

        AttestationRecord memory attestation =
            instance.registry.findAttestation(defaultModule1, attester);
        assertTrue(attestation.revocationTime != 0);
    }

    function testRevoke__RevertWhen__AttestationNotFound() public {
        address attester = address(this);
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector));
        instance.revokeAttestation(defaultModule1, defaultSchema1, attester);
    }

    function testRevoke__RevertWhen__InvalidSchema() public {
        address attester = address(this);
        instance.mockAttestation(defaultSchema1, defaultModule1);

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instance.revokeAttestation(defaultModule1, SchemaUID.wrap(0), attester);
    }

    function testRevoke__RevertWhen__NotOriginalAttester() public {
        address attester = address(this);
        address notAttester = makeAddr("notAttester");

        instance.mockAttestation(defaultSchema1, defaultModule1);

        RevocationRequestData memory revoke =
            RevocationRequestData({ moduleAddr: defaultModule1, attester: attester, value: 0 });

        RevocationRequest memory req =
            RevocationRequest({ schemaUID: defaultSchema1, data: revoke });

        vm.startPrank(notAttester);
        vm.expectRevert(abi.encodeWithSelector(AccessDenied.selector));
        instance.registry.revoke(req);
        vm.stopPrank();
    }

    function testRevoke__RevertWhen__AlreadyRevoked() public {
        address attester = address(this);
        instance.mockAttestation(defaultSchema1, defaultModule1);
        instance.revokeAttestation(defaultModule1, defaultSchema1, attester);

        AttestationRecord memory attestation =
            instance.registry.findAttestation(defaultModule1, attester);
        assertTrue(attestation.revocationTime != 0);

        vm.expectRevert(abi.encodeWithSelector(IAttestation.AlreadyRevoked.selector));
        instance.revokeAttestation(defaultModule1, defaultSchema1, attester);
    }

    function testMultiRevoke() public {
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
