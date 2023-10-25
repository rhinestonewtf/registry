// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "../utils/BaseTest.t.sol";

import {
    RegistryIntegration,
    IQuery
} from "../../src/integrations/examples/SimpleRegistryIntegration.sol";

contract TestHarness is RegistryIntegration {
    constructor(address _registry, address _authority) RegistryIntegration(_registry, _authority) { }

    function query(address _contract)
        public
        view
        onlyWithRegistryCheck(_contract)
        returns (uint256)
    {
        return 1;
    }
}

/// @title SimpleRegistryIntegrationTest
/// @author zeroknots
contract SimpleRegistryIntegrationTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    TestHarness harness;

    function setUp() public override {
        super.setUp();

        harness = new TestHarness(address(instancel1.registry), vm.addr(auth1k));
    }

    function testGasRegistryCheck() public {
        instancel1.mockAttestation(defaultSchema1, auth1k, defaultModule1);
        harness.query(defaultModule1);
    }
}
