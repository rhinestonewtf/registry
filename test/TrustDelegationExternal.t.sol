// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Attestation.t.sol";
import "src/DataTypes.sol";
import { LibSort } from "solady/utils/LibSort.sol";

contract TrustTestExternal is AttestationTest {
    using LibSort for address[];

    function setUp() public override {
        super.setUp();
        // test_WhenAttestingWithNoAttestationData(address(module1));
    }

    modifier whenSettingAttester() {
        _;
    }

    function test_WhenSupplyingExternal() external whenSettingAttester {
        // It should set.
        test_WhenUsingValidECDSA();
        address[] memory trustedAttesters = new address[](2);
        trustedAttesters[0] = address(attester1.addr);
        trustedAttesters[1] = address(attester2.addr);

        registry.check(address(module1), ModuleType.wrap(1), attester1.addr);
        registry.check(address(module1), ModuleType.wrap(2), attester1.addr);
        vm.expectRevert();
        registry.check(address(module1), ModuleType.wrap(3), attester1.addr);
        registry.checkN(address(module1), trustedAttesters, 1);

    }
}
