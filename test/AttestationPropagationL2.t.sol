// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./RSAttestation.t.sol";

/// @title AttestationPropagationL2Test
/// @author zeroknots
contract AttestationPropagationL2Test is RSAttestationTest {
    bytes32 attestationUid1;
    bytes32 attestationUid2;
    address[] destinationAdapters;

    function setUp() public override {
        super.setUp();
        (attestationUid1, attestationUid2) = testCreateChainedAttestation();
    }

    function testPropagateWithHashi() public {
        address[] memory bridges = new address[](1);
        bridges[0] = address(1);
        instancel1.registry.propagateAttest({
            to: address(instancel2.registry),
            toChainId: 0,
            attestationId: attestationUid1,
            moduleOnL2: address(0), // todo
            destinationAdapters: destinationAdapters
        });

        // yaho dispatch message

        // make adapter aray with ambMeessageRelay

        // relay messagestoadapters ( supply destinationAdapters)

        // on L2
        // yaru execute messages with oracle adapter (ambAdapter)A
    }

    function testPropagateNonExistingSchema() public {
        assertTrue(false);
    }

    function testPropagateMissingRefUID() public {
        assertTrue(false);
    }

    function testPropagateRefUID() public {
        assertTrue(false);
    }
}
