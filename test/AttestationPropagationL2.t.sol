// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./RSRegistry.t.sol";

/// @title AttestationPropagationL2Test
/// @author zeroknots
contract AttestationPropagationL2Test is RSRegistryTest {
    function setUp() public override {
        super.setUp();
    }

    function testPropagateWithHashi() public {
        assertTrue(false);
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
