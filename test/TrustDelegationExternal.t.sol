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
        _make_WhenUsingValidECDSA(attester1);
        address[] memory trustedAttestersSingle = new address[](1);
        trustedAttestersSingle[0] = address(attester1.addr);

        address[] memory trustedAttesters = new address[](2);
        trustedAttesters[0] = address(attester1.addr);
        trustedAttesters[1] = address(attester2.addr);

        trustedAttesters.sort();

        registry.check(address(module1), ModuleType.wrap(1), trustedAttestersSingle, 1);
        registry.check(address(module1), ModuleType.wrap(2), trustedAttestersSingle, 1);
        vm.expectRevert();
        registry.check(address(module1), ModuleType.wrap(3), trustedAttestersSingle, 1);
        registry.check(address(module1), trustedAttesters, 1);
        registry.check(address(module1), ModuleType.wrap(1), trustedAttesters, 1);
        vm.expectRevert();
        registry.check(address(module1), trustedAttesters, 2);
        vm.expectRevert();
        registry.check(address(module1), ModuleType.wrap(1), trustedAttesters, 2);
        _make_WhenUsingValidECDSA(attester2);
        registry.check(address(module1), trustedAttesters, 2);
        registry.check(address(module1), trustedAttesters, 2);

        trustedAttesters = new address[](4);
        Account memory attester3 = makeAccount("attester3");
        Account memory attester4 = makeAccount("attester4");
        trustedAttesters[0] = address(attester1.addr);
        trustedAttesters[1] = address(attester3.addr);
        trustedAttesters[2] = address(attester4.addr);
        trustedAttesters[3] = address(attester2.addr);

        vm.expectRevert();
        registry.check(address(module1), trustedAttesters, 2);

        trustedAttesters.sort();
        registry.check(address(module1), trustedAttesters, 2);
    }
}
