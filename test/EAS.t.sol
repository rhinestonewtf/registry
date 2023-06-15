// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@eas/EAS.sol";
import "@eas/Common.sol";
import "@eas/IEAS.sol";
import "@eas/SchemaRegistry.sol";
import "@eas/resolver/ISchemaResolver.sol";

import "./mock/SimpleResolver.sol";

/// @title EASTest
/// @author zeroknots
contract EASTest is Test {
    SchemaRegistry schemaRegistry;
    EAS eas;

    SimpleResolver resolver;

    address attester1 = makeAddr("attester1");
    address attester2 = makeAddr("attester2");

    function setUp() public virtual {
        schemaRegistry = new SchemaRegistry();
        eas = new EAS(schemaRegistry);
        resolver = new SimpleResolver(eas);
    }

    function testRegisterSchema(
        string memory schema,
        address _resolver
    )
        public
        returns (bytes32 uid)
    {
        uid = schemaRegistry.register(schema, ISchemaResolver(_resolver), true);
    }

    function testAttest() public {
        string memory schema = "bool secure";

        bytes32 schemaUid = testRegisterSchema(schema, address(resolver));

        AttestationRequestData memory ard = AttestationRequestData({
            recipient: address(0x12345),
            expirationTime: uint64(0),
            revocable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });

        AttestationRequest memory attReq = AttestationRequest({ schema: schemaUid, data: ard });

        vm.prank(attester1);
        bytes32 attestationId = eas.attest(attReq);

        Attestation memory attestationFromEAS = eas.getAttestation(attestationId);
        assertEq(attestationId, attestationFromEAS.uid);
        assertEq(attestationFromEAS.schema, schemaUid);

        attReq.data.refUID = attestationId;

        vm.prank(attester2);
        bytes32 attestationId2 = eas.attest(attReq);
    }
}
