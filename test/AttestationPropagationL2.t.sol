// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./Attestation.t.sol";
import "../src/lib/ModuleDeploymentLib.sol";

/// @title AttestationPropagationL2Test
/// @author zeroknots
contract AttestationPropagationL2Test is AttestationTest {
    using RegistryTestLib for RegistryInstance;
    using ModuleDeploymentLib for address;

    bytes32 attestationUid1;
    bytes32 attestationUid2;

    function setUp() public override {
        super.setUp();
        (attestationUid1, attestationUid2) = testCreateChainedAttestation();
    }

    function testPropagateWithHashi() public {
        bytes32 schemaUID =
            instancel1.registerSchema("Propagation Test", ISchemaResolver(address(0)));
        bytes32 schemaUID2 =
            instancel2.registerSchema("Propagation Test", ISchemaResolver(address(0)));

        assertEq(schemaUID, schemaUID2);

        bytes memory bytecode = type(MockModuleWithArgs).creationCode;
        address moduleAddr = instancel1.deployAndRegister({
            schemaUID: schemaUID,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_131_123)
        });
        attestationUid1 = instancel1.mockAttestation(schemaUID, auth1k, moduleAddr);

        instancel2.registry.register({ schemaUID: schemaUID2, moduleAddress: moduleAddr, data: "" });
        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationId: attestationUid1,
            moduleOnL2: moduleAddr
        });

        uint256[] memory messageIds = toUint256Array(messageIdsBytes32);
        address[] memory adapters = new address[](1);
        adapters[0] = address(hashiEnv.ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(hashiEnv.ambAdapter);
        instancel1.yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](1);
        senders[0] = address(instancel1.registry);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(hashiEnv.ambAdapter));

        instancel2.yaru.executeMessages(messages, messageIds, senders, oracleAdapter);
    }

    function testPropagateMultipleAttestations() public {
        bytes32 schemaUID =
            instancel1.registerSchema("Propagation Test", ISchemaResolver(address(0)));
        bytes32 schemaUID2 =
            instancel2.registerSchema("Propagation Test", ISchemaResolver(address(0)));

        assertEq(schemaUID, schemaUID2);

        bytes memory bytecode = type(MockModuleWithArgs).creationCode;
        address moduleAddr = instancel1.deployAndRegister({
            schemaUID: schemaUID,
            bytecode: bytecode,
            constructorArgs: abi.encode(313_131_123)
        });
        attestationUid1 = instancel1.mockAttestation(schemaUID, auth1k, moduleAddr);
        bytes32 attestation2 = instancel1.mockAttestation(schemaUID, 1, moduleAddr);
        bytes32 attestation3 = instancel1.mockAttestation(schemaUID, 2, moduleAddr);
        bytes32 attestation4 = instancel1.mockAttestation(schemaUID, 3, moduleAddr);

        instancel2.registry.register({ schemaUID: schemaUID2, moduleAddress: moduleAddr, data: "" });

        bytes32[] memory attestationIds = new bytes32[](4);
        attestationIds[0] = attestationUid1;
        attestationIds[1] = attestation2;
        attestationIds[2] = attestation3;
        attestationIds[3] = attestation4;

        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationIds: attestationIds,
            moduleOnL2: moduleAddr
        });

        assertEq(messages.length, 4);

        uint256[] memory messageIds = toUint256Array(messageIdsBytes32);
        assertEq(messageIds.length, 4);
        address[] memory adapters = new address[](1);
        adapters[0] = address(hashiEnv.ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(hashiEnv.ambAdapter);
        instancel1.yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](4);
        senders[0] = address(instancel1.registry);
        senders[1] = address(instancel1.registry);
        senders[2] = address(instancel1.registry);
        senders[3] = address(instancel1.registry);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(hashiEnv.ambAdapter));

        instancel2.yaru.executeMessages(messages, messageIds, senders, oracleAdapter);
    }

    function testPropagateChainedAttestations() public {
        bytes32[] memory attestationIds = new bytes32[](2);
        attestationIds[0] = attestationUid1;
        attestationIds[1] = attestationUid2;

        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationIds: attestationIds,
            moduleOnL2: defaultModule1
        });
        uint256[] memory messageIds = toUint256Array(messageIdsBytes32);
        address[] memory adapters = new address[](1);
        adapters[0] = address(hashiEnv.ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(hashiEnv.ambAdapter);
        instancel1.yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](2);
        senders[0] = address(instancel1.registry);
        senders[1] = address(instancel1.registry);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(hashiEnv.ambAdapter));

        instancel2.yaru.executeMessages(messages, messageIds, senders, oracleAdapter);
    }

    function testPropagateTwice() public {
        testPropagateChainedAttestations();
        testPropagateChainedAttestations();
    }

    function testPropagateChainWithBrokenChain() public {
        testPropagateChainedAttestations();
        instancel1.revokeAttestation(attestationUid1, defaultSchema1, auth1k);
        testPropagateChainedAttestations();
        AttestationRecord memory attestation =
            instancel2.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
    }

    function testPropagateRevocedAttestation() public {
        testPropagateChainedAttestations();
        instancel1.revokeAttestation(attestationUid1, defaultSchema1, auth1k);
        testPropagateChainedAttestations();
        AttestationRecord memory attestation =
            instancel2.registry.findAttestation(defaultModule1, vm.addr(auth1k));
        assertTrue(attestation.revocationTime != 0);
    }

    function testPropagateAttestationL2NonexistingSchema() public {
        bytes32 newSchema = instancel1.registerSchema("New", ISchemaResolver(address(0)));
        address module = instancel1.deployAndRegister(
            newSchema, type(MockModuleWithArgs).creationCode, abi.encode(428)
        );
        bytes32 attestationUid = instancel1.mockAttestation(newSchema, auth1k, module);

        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationId: attestationUid,
            moduleOnL2: module
        });

        uint256[] memory messageIds = toUint256Array(messageIdsBytes32);
        address[] memory adapters = new address[](1);
        adapters[0] = address(hashiEnv.ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(hashiEnv.ambAdapter);
        instancel1.yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](1);
        senders[0] = address(instancel1.registry);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(hashiEnv.ambAdapter));

        vm.expectRevert(
            abi.encodeWithSelector(Yaru.CallFailed.selector, address(instancel2.yaru), 0)
        );
        instancel2.yaru.executeMessages(messages, messageIds, senders, oracleAdapter);
    }

    function testPropagateAttestationL2NonExistingRefUID() public {
        bytes32 newSchema = instancel1.registerSchema("New", ISchemaResolver(address(0)));
        bytes32 newSchema2 = instancel2.registerSchema("New", ISchemaResolver(address(0)));
        address module = instancel1.deployAndRegister(
            newSchema, type(MockModuleWithArgs).creationCode, abi.encode(428)
        );

        AttestationRequestData memory attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            propagateable: true,
            refUID: "non-existing-ref-uid",
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(NotFound.selector));
        instancel1.newAttestation(newSchema, auth1k, attData);

        attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        bytes32 attestationUid = instancel1.newAttestation(newSchema, auth1k, attData);
        assertTrue(attestationUid != bytes32(0));

        attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            propagateable: true,
            refUID: attestationUid,
            data: abi.encode(true),
            value: 0
        });

        attestationUid2 = instancel1.newAttestation(newSchema, auth1k, attData);
        assertTrue(attestationUid != attestationUid2);

        vm.etch(module, "asdfqqwerasdf");

        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationId: attestationUid2,
            moduleOnL2: module
        });

        uint256[] memory messageIds = toUint256Array(messageIdsBytes32);
        address[] memory adapters = new address[](1);
        adapters[0] = address(hashiEnv.ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(hashiEnv.ambAdapter);
        instancel1.yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](1);
        senders[0] = address(instancel1.registry);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(hashiEnv.ambAdapter));

        // vm.expectRevert(
        //     abi.encodeWithSelector(Attestation.InvalidAttestationRefUID.selector, attestationUid));
        vm.expectRevert(
            abi.encodeWithSelector(Yaru.CallFailed.selector, address(instancel2.yaru), 0)
        );
        instancel2.yaru.executeMessages(messages, messageIds, senders, oracleAdapter);
    }

    function testPropagateIncompatibleBytecode() public {
        bytes32[] memory attestationIds = new bytes32[](2);
        attestationIds[0] = attestationUid1;
        attestationIds[1] = attestationUid2;

        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationIds: attestationIds,
            moduleOnL2: defaultModule1
        });

        bytes32 moduleHashBefore = defaultModule1.codeHash();
        vm.etch(defaultModule1, "asdfasdfasdf");
        bytes32 moduleHashAfter = defaultModule1.codeHash();
        assertTrue(moduleHashBefore != moduleHashAfter);

        uint256[] memory messageIds = toUint256Array(messageIdsBytes32);
        address[] memory adapters = new address[](1);
        adapters[0] = address(hashiEnv.ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(hashiEnv.ambAdapter);
        instancel1.yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](2);
        senders[0] = address(instancel1.registry);
        senders[1] = address(instancel1.registry);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(hashiEnv.ambAdapter));

        vm.expectRevert(
            abi.encodeWithSelector(Yaru.CallFailed.selector, address(instancel2.yaru), 0)
        );
        instancel2.yaru.executeMessages(messages, messageIds, senders, oracleAdapter);
    }

    function testPropagateNonExistingAttestation() public {
        bytes32[] memory attestationIds = new bytes32[](2);
        attestationIds[0] = attestationUid1;
        attestationIds[1] = "non-existing-attestation-uid";

        bytes32 moduleHashBefore = defaultModule1.codeHash();
        vm.etch(defaultModule1, "asdfasdfasdf");
        bytes32 moduleHashAfter = defaultModule1.codeHash();
        assertTrue(moduleHashBefore != moduleHashAfter);

        vm.expectRevert(abi.encodeWithSelector(Attestation.InvalidAttestation.selector));
        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationIds: attestationIds,
            moduleOnL2: defaultModule1
        });
    }

    function testNonOwnerPropagate() public {
        testPropagateChainedAttestations();
        address bob = makeAddr("bob");
        vm.prank(bob);
        testPropagateChainedAttestations();
    }

    function testPropagateNonExistingSchema() public {
        bytes32 newSchema = instancel1.registerSchema("New", ISchemaResolver(address(0)));
        address module = instancel1.deployAndRegister(
            newSchema, type(MockModuleWithArgs).creationCode, abi.encode(428)
        );

        AttestationRequestData memory attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            propagateable: true,
            refUID: "non-existing-ref-uid",
            data: abi.encode(true),
            value: 0
        });

        vm.expectRevert(abi.encodeWithSelector(NotFound.selector));
        instancel1.newAttestation(newSchema, auth1k, attData);

        attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        bytes32 attestationUid = instancel1.newAttestation(newSchema, auth1k, attData);
        assertTrue(attestationUid != bytes32(0));

        attData = AttestationRequestData({
            subject: module,
            expirationTime: uint48(0),
            propagateable: true,
            refUID: attestationUid,
            data: abi.encode(true),
            value: 0
        });

        attestationUid2 = instancel1.newAttestation(newSchema, auth1k, attData);
        assertTrue(attestationUid != attestationUid2);

        vm.etch(module, "asdfqqwerasdf");

        (Message[] memory messages, bytes32[] memory messageIdsBytes32) = instancel1
            .registry
            .propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationId: attestationUid2,
            moduleOnL2: module
        });

        uint256[] memory messageIds = toUint256Array(messageIdsBytes32);
        address[] memory adapters = new address[](1);
        adapters[0] = address(hashiEnv.ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(hashiEnv.ambAdapter);
        instancel1.yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](1);
        senders[0] = address(instancel1.registry);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(hashiEnv.ambAdapter));

        // vm.expectRevert(
        //     abi.encodeWithSelector(Attestation.InvalidAttestationRefUID.selector, attestationUid));
        vm.expectRevert(
            abi.encodeWithSelector(Yaru.CallFailed.selector, address(instancel2.yaru), 0)
        );
        instancel2.yaru.executeMessages(messages, messageIds, senders, oracleAdapter);
    }

    function toUint256Array(bytes32[] memory array) internal pure returns (uint256[] memory) {
        uint256[] memory array2 = new uint256[](array.length);
        for (uint256 i; i < array.length; ++i) {
            array2[i] = uint256(array[i]);
        }
        return array2;
    }
}
