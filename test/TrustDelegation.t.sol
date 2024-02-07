// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Attestation.t.sol";
import "src/DataTypes.sol";
import { LibSort } from "solady/utils/LibSort.sol";

contract TrustTest is AttestationTest {
    using LibSort for address[];

    function setUp() public override {
        super.setUp();
        // test_WhenAttestingWithNoAttestationData(address(module1));
    }

    modifier whenSettingAttester() {
        _;
    }

    function test_WhenSupplyingOneAttester() external whenSettingAttester {
        // It should set.
        address[] memory trustedAttesters = new address[](1);
        trustedAttesters[0] = address(attester1.addr);
        registry.trustAttesters(1, trustedAttesters);
        address[] memory result = registry.getTrustedAttesters();
        assertEq(result.length, 1);
        assertEq(result[0], address(attester1.addr));
    }

    function test_WhenSupplyingManyAttesters(address[] memory attesters)
        external
        whenSettingAttester
    {
        vm.assume(attesters.length < 100);
        vm.assume(attesters.length > 0);
        for (uint256 i; i < attesters.length; i++) {
            vm.assume(attesters[i] != address(0));
        }
        attesters.sort();
        attesters.uniquifySorted();
        registry.trustAttesters(uint8(attesters.length), attesters);
        // It should set.
        // It should emit event.
        address[] memory result = registry.getTrustedAttesters();

        assertEq(result.length, attesters.length);
        for (uint256 i; i < attesters.length; i++) {
            assertEq(result[i], attesters[i]);
        }
    }

    function test_WhenSupplyingSameAttesterMultipleTimes() external whenSettingAttester {
        address[] memory attesters = new address[](2);
        attesters[0] = address(attester1.addr);
        attesters[1] = address(attester1.addr);
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidTrustedAttesterInput.selector));
        registry.trustAttesters(uint8(attesters.length), attesters);
    }

    modifier whenQueryingRegisty() {
        _;
    }

    function test_WhenNoAttestersSet() external whenQueryingRegisty {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.AttestationNotFound.selector));
        registry.check(address(module1), ModuleType.wrap(1));
        vm.expectRevert(abi.encodeWithSelector(IRegistry.AttestationNotFound.selector));
        registry.checkForAccount(makeAddr("foo"), address(module1), ModuleType.wrap(1));
        vm.expectRevert(abi.encodeWithSelector(IRegistry.AttestationNotFound.selector));
        registry.check(address(module1));
        vm.expectRevert(abi.encodeWithSelector(IRegistry.AttestationNotFound.selector));
        registry.checkForAccount(makeAddr("foo"), address(module1));
    }

    function test_WhenAttesterSetButNoAttestationMade() external whenQueryingRegisty {
        // It should revert.
    }

    function test_WhenAttestersSetButThresholdTooLow() external whenQueryingRegisty {
        // It should revert.
    }

    function test_WhenAttestersSetAndAllOk() external whenQueryingRegisty {
        // It should not revert.
    }
}
