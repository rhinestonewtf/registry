// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import {
    Attestation,
    MultiDelegatedAttestationRequest,
    AttestationRecord,
    IAttestation,
    InvalidSchema,
    NotFound,
    AccessDenied
} from "../src/base/Attestation.sol";

import { ERC1271Attester, EXPECTED_SIGNATURE } from "./utils/ERC1271Attester.sol";

import {
    BaseTest,
    RegistryTestLib,
    RegistryInstance,
    console2,
    AttestationRequestData,
    DelegatedAttestationRequest,
    MockModuleWithArgs,
    ResolverUID,
    IResolver,
    SchemaUID,
    ISchemaValidator
} from "./utils/BaseTest.t.sol";

import {
    MultiAttestationRequest,
    MultiRevocationRequest,
    RevocationRequestData
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
        instancel1.mockAttestation(defaultSchema1, defaultModule1);
    }

    function testAttest__RevertWhen__InvalidExpirationTime() public {
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(1),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidExpirationTime.selector));
        instancel1.newAttestation(defaultSchema1, attData);
    }

    function testAttest__RevertWhen__ZeroImplementation() public {
        AttestationRequestData memory attData = AttestationRequestData({
            subject: address(0x69),
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instancel1.newAttestation(defaultSchema1, attData);
    }

    function testAttest__RevertWhen__InvalidSchema() public {
        AttestationRequestData memory attData = AttestationRequestData({
            subject: address(0x69),
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instancel1.newAttestation(SchemaUID.wrap(0), attData);
    }

    function testAttest__RevertWhen__ValidatorSaysInvalidAttestation() public {
        SchemaUID schemaId = instancel1.registerSchema("", ISchemaValidator(falseSchemaValidator));
        AttestationRequestData memory attData = AttestationRequestData({
            subject: address(0x69),
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instancel1.newAttestation(schemaId, attData);
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
            subject: defaultModule1,
            expirationTime: uint48(0),
            data: data,
            value: 0
        });

        instancel1.newAttestation(defaultSchema1, attData);
    }

    function testMultiAttest() public {
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        instancel1.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__InvalidSchema() public {
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: SchemaUID.wrap(0), data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instancel1.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__ValidatorSaysInvalidAttestation() public {
        SchemaUID schemaId = instancel1.registerSchema("", ISchemaValidator(falseSchemaValidator));
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: schemaId, data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instancel1.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__InvalidExpirationTime() public {
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(1),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidExpirationTime.selector));
        instancel1.registry.multiAttest(reqs);
    }

    function testMultiAttest__RevertWhen__ZeroImplementation() public {
        SchemaUID schemaId = instancel1.registerSchema("", ISchemaValidator(falseSchemaValidator));
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        AttestationRequestData memory attData1 = AttestationRequestData({
            subject: address(0x69),
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: anotherModule,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData[] memory attArray = new AttestationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiAttestationRequest[] memory reqs = new MultiAttestationRequest[](1);
        MultiAttestationRequest memory req1 =
            MultiAttestationRequest({ schemaUID: schemaId, data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        instancel1.registry.multiAttest(reqs);
    }

    function testRevoke() public {
        address attester = address(this);
        instancel1.mockAttestation(defaultSchema1, defaultModule1);
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, attester);

        AttestationRecord memory attestation =
            instancel1.registry.findAttestation(defaultModule1, attester);
        assertTrue(attestation.revocationTime != 0);
    }

    function testRevoke__RevertWhen__AttestationNotFound() public {
        address attester = address(this);
        vm.expectRevert(abi.encodeWithSelector(NotFound.selector));
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, attester);
    }

    function testRevoke__RevertWhen__InvalidSchema() public {
        address attester = address(this);
        instancel1.mockAttestation(defaultSchema1, defaultModule1);

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instancel1.revokeAttestation(defaultModule1, SchemaUID.wrap(0), attester);
    }

    function testRevoke__RevertWhen__NotOriginalAttester() public {
        // @TODO: fix this
        // address attester = address(this);
        // address notAttester = makeAddr("notAttester");

        // instancel1.mockAttestation(defaultSchema1, defaultModule1);

        // vm.startPrank(notAttester);
        // vm.expectRevert(abi.encodeWithSelector(AccessDenied.selector));
        // instancel1.revokeAttestation(defaultModule1, defaultSchema1, attester);
        // vm.stopPrank();
    }

    function testRevoke__RevertWhen__AlreadyRevoked() public {
        address attester = address(this);
        instancel1.mockAttestation(defaultSchema1, defaultModule1);
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, attester);

        AttestationRecord memory attestation =
            instancel1.registry.findAttestation(defaultModule1, attester);
        assertTrue(attestation.revocationTime != 0);

        vm.expectRevert(abi.encodeWithSelector(IAttestation.AlreadyRevoked.selector));
        instancel1.revokeAttestation(defaultModule1, defaultSchema1, attester);
    }

    function testMultiRevoke() public {
        address attester = address(this);
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instancel1.mockAttestation(defaultSchema1, defaultModule1);
        instancel1.mockAttestation(defaultSchema1, anotherModule);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ subject: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ subject: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        instancel1.registry.multiRevoke(reqs);

        AttestationRecord memory attestation =
            instancel1.registry.findAttestation(defaultModule1, attester);
        assertTrue(attestation.revocationTime != 0);

        AttestationRecord memory attestation2 =
            instancel1.registry.findAttestation(anotherModule, attester);
        assertTrue(attestation2.revocationTime != 0);
    }

    function testMultiRevoke__RevertWhen__InvalidSchema() public {
        address attester = address(this);
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instancel1.mockAttestation(defaultSchema1, defaultModule1);
        instancel1.mockAttestation(defaultSchema1, anotherModule);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ subject: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ subject: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: SchemaUID.wrap(0), data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(InvalidSchema.selector));
        instancel1.registry.multiRevoke(reqs);
    }

    function testMultiRevoke__RevertWhen__AttestationNotFound() public {
        address attester = address(this);
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        RevocationRequestData memory attData1 =
            RevocationRequestData({ subject: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ subject: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        vm.expectRevert(abi.encodeWithSelector(NotFound.selector));
        instancel1.registry.multiRevoke(reqs);
    }

    function testMultiRevoke__RevertWhen__NotOriginalAttester() public {
        address attester = address(this);
        address notAttester = makeAddr("notAttester");
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instancel1.mockAttestation(defaultSchema1, defaultModule1);
        instancel1.mockAttestation(defaultSchema1, anotherModule);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ subject: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ subject: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        vm.startPrank(notAttester);
        vm.expectRevert(abi.encodeWithSelector(AccessDenied.selector));
        instancel1.registry.multiRevoke(reqs);
        vm.stopPrank();
    }

    function testMultiRevoke__RevertWhen__AlreadyRevoked() public {
        address attester = address(this);
        address anotherModule = instancel1.deployAndRegister(
            defaultResolver, type(MockModuleWithArgs).creationCode, abi.encode(1_234_819_239_123)
        );

        instancel1.mockAttestation(defaultSchema1, defaultModule1);
        instancel1.mockAttestation(defaultSchema1, anotherModule);

        RevocationRequestData memory attData1 =
            RevocationRequestData({ subject: defaultModule1, attester: attester, value: 0 });

        RevocationRequestData memory attData2 =
            RevocationRequestData({ subject: anotherModule, attester: attester, value: 0 });

        RevocationRequestData[] memory attArray = new RevocationRequestData[](
            2
        );
        attArray[0] = attData1;
        attArray[1] = attData2;

        MultiRevocationRequest[] memory reqs = new MultiRevocationRequest[](1);
        MultiRevocationRequest memory req1 =
            MultiRevocationRequest({ schemaUID: defaultSchema1, data: attArray });
        reqs[0] = req1;

        instancel1.registry.multiRevoke(reqs);

        vm.expectRevert(abi.encodeWithSelector(IAttestation.AlreadyRevoked.selector));
        instancel1.registry.multiRevoke(reqs);
    }

    // function testReAttest() public {
    //     AttestationRequestData memory attData = AttestationRequestData({
    //         subject: defaultModule1,
    //         expirationTime: uint48(0),
    //         data: "123",
    //         value: 0
    //     });
    //     instancel1.newAttestation(defaultSchema1, auth1k, attData);
    //     instancel1.revokeAttestation(defaultModule1, defaultSchema1, auth1k);
    //     vm.warp(400);

    //     attData.data = "456";
    //     uint48 time = uint48(block.timestamp);
    //     instancel1.newAttestation(defaultSchema1, auth1k, attData);

    //     AttestationRecord memory attestation =
    //         instancel1.registry.findAttestation(defaultModule1, vm.addr(auth1k));

    //     assertTrue(attestation.time == time);
    // }

    // function testAttestationNonExistingSchema() public {
    //     // TODO
    //     assertTrue(true);
    // }

    // function testERC1721Attestation() public {
    //     ERC1271Attester attester = new ERC1271Attester();

    //     AttestationRequestData memory attData = AttestationRequestData({
    //         subject: defaultModule1,
    //         expirationTime: uint48(0),
    //         data: abi.encode(true),
    //         value: 0
    //     });

    //     bytes memory sig = EXPECTED_SIGNATURE;

    //     DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
    //         schemaUID: defaultSchema1,
    //         data: attData,
    //         signature: sig,
    //         attester: address(attester)
    //     });

    //     instancel1.registry.attest(req);
    // }
}
