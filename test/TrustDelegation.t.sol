// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract TrustTest {
    modifier whenSettingAttester() {
        _;
    }

    function test_WhenSupplyingSameAttesterMultipleTimes() external whenSettingAttester {
        // It should revert.
    }

    function test_WhenSupplyingOneAttester() external whenSettingAttester {
        // It should set.
        // It should emit event.
    }

    function test_WhenSupplyingManyAttesters() external whenSettingAttester {
        // It should set.
        // It should emit event.
    }

    modifier whenQueryingRegisty() {
        _;
    }

    function test_WhenNoAttestersSet() external whenQueryingRegisty {
        // It should revert.
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
