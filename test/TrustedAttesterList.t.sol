// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Attestation.t.sol";
import "src/DataTypes.sol";
import { LibSort } from "solady/utils/LibSort.sol";

contract POCTest is AttestationTest {
    using LibSort for address[];

    function setUp() public override {
        super.setUp();
    }

    function testPOC() external prankWithAccount(smartAccount1) {
        uint8 threshold = 1;
        address[] memory trustedAttesters = new address[](3);
        trustedAttesters[0] = address(attester1.addr);
        trustedAttesters[1] = address(attester2.addr);
        trustedAttesters[2] = makeAddr("attester3");

        trustedAttesters.sort();
        trustedAttesters.uniquifySorted();

        registry.trustAttesters(threshold, trustedAttesters);

        address[] memory result = registry.findTrustedAttesters(smartAccount1.addr);

        assertEq(result.length, trustedAttesters.length);
        for (uint256 i; i < trustedAttesters.length; i++) {
            assertEq(result[i], trustedAttesters[i]);
        }

        _make_WhenUsingValidECDSA(attester2);
        registry.check(address(module1), ModuleType.wrap(1));

        address[] memory newTrustedAttesters = new address[](1);
        newTrustedAttesters[0] = address(attester1.addr);
        registry.trustAttesters(1, newTrustedAttesters);
        address[] memory newResult = registry.findTrustedAttesters(smartAccount1.addr);
        assertEq(newResult.length, 1);
        assertEq(newResult[0], address(attester1.addr));

        registry.check(address(module1), ModuleType.wrap(1));
    }
}
