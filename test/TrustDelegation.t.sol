// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Attestation.t.sol";
import "src/DataTypes.sol";
import { LibSort } from "solady/utils/LibSort.sol";
import { VmSafe } from "forge-std/Vm.sol";
import { ERC4337SpecsParser } from "erc4337-validation/SpecsParser.sol";

contract TrustTest is AttestationTest {
    using LibSort for address[];
    using ERC4337SpecsParser for VmSafe.AccountAccess;

    function setUp() public override {
        super.setUp();
        // test_WhenAttestingWithNoAttestationData(address(module1));
    }

    modifier whenSettingAttester() {
        _;
    }

    function test_WhenSupplyingOneAttester() external whenSettingAttester prankWithAccount(smartAccount1) {
        // It should set.
        address[] memory trustedAttesters = new address[](1);
        trustedAttesters[0] = address(attester1.addr);
        registry.trustAttesters(1, trustedAttesters);
        address[] memory result = registry.findTrustedAttesters(smartAccount1.addr);
        assertEq(result.length, 1);
        assertEq(result[0], address(attester1.addr));
    }

    function test_WhenSupplyingManyAttesters(
        uint8 threshold,
        address[] memory attesters
    )
        public
        whenSettingAttester
        prankWithAccount(smartAccount1)
    {
        vm.assume(attesters.length < 100);
        vm.assume(attesters.length > 0);
        vm.assume(threshold <= attesters.length);
        for (uint256 i; i < attesters.length; i++) {
            vm.assume(attesters[i] != address(0));
        }
        attesters.sort();
        attesters.uniquifySorted();
        vm.assume(threshold <= attesters.length);
        registry.trustAttesters(threshold, attesters);
        // It should set.
        // It should emit event.
        address[] memory result = registry.findTrustedAttesters(smartAccount1.addr);

        assertEq(result.length, attesters.length);
        for (uint256 i; i < attesters.length; i++) {
            assertEq(result[i], attesters[i]);
        }
    }

    function test_ManyAttesters() public {
        _make_WhenUsingValidECDSA(attester1);
        _make_WhenUsingValidECDSA(attester2);
        Account memory attester3 = makeAccount("attester3");
        Account memory attester4 = makeAccount("attester4");
        address[] memory trustedAttesters = new address[](4);
        trustedAttesters[0] = address(attester1.addr);
        trustedAttesters[1] = address(attester3.addr);
        trustedAttesters[2] = address(attester4.addr);
        trustedAttesters[3] = address(attester2.addr);

        trustedAttesters.sort();
        trustedAttesters.uniquifySorted();

        vm.startPrank(smartAccount1.addr);
        registry.trustAttesters(2, trustedAttesters);

        registry.check(address(module1), ModuleType.wrap(1));
        registry.check(address(module1), ModuleType.wrap(2));
        registry.trustAttesters(3, trustedAttesters);
        vm.expectRevert();
        registry.check(address(module1), ModuleType.wrap(1));
    }

    function test_WhenSupplyingSameAttesterMultipleTimes() external whenSettingAttester {
        address[] memory attesters = new address[](2);
        attesters[0] = address(attester1.addr);
        attesters[1] = address(attester1.addr);
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidTrustedAttesterInput.selector));
        registry.trustAttesters(uint8(attesters.length), attesters);
    }

    modifier whenQueryingRegistry() {
        _;
    }

    function test_WhenNoAttestersSet() external whenQueryingRegistry {
        // It should revert.
        vm.expectRevert();
        registry.check(address(module1), ModuleType.wrap(1));
        vm.expectRevert();
        registry.checkForAccount(makeAddr("foo"), address(module1), ModuleType.wrap(1));
        vm.expectRevert();
        registry.check(address(module1));
        vm.expectRevert();
        registry.checkForAccount(makeAddr("foo"), address(module1));
    }

    function test_WhenAttesterSetButNoAttestationMade() external whenQueryingRegistry {
        // It should revert.
    }

    function test_WhenAttestersSetButThresholdTooLow() external whenQueryingRegistry {
        // It should revert.
    }

    function test_WhenAttestersSetAndAllOk() external whenQueryingRegistry {
        test_WhenUsingValidECDSA();

        vm.startPrank(smartAccount1.addr);
        // It should not revert.
        address[] memory attesters = new address[](2);
        attesters[0] = address(attester1.addr);
        attesters[1] = address(attester2.addr);
        registry.trustAttesters(1, attesters);

        registry.check(address(module1), ModuleType.wrap(1));
        registry.check(address(module1), ModuleType.wrap(2));
        vm.expectRevert();
        registry.check(address(module1), ModuleType.wrap(3));
    }

    function test_WhenAttestersSetCheckOnlyOneThreshold() external whenQueryingRegistry {
        test_WhenUsingValidECDSA();

        vm.startPrank(smartAccount1.addr);
        // It should not revert.
        address[] memory attesters = new address[](2);
        attesters[0] = address(makeAddr("foo"));
        attesters[1] = address(attester1.addr);

        attesters.sort();
        attesters.uniquifySorted();
        registry.trustAttesters(1, attesters);

        registry.check(address(module1), ModuleType.wrap(1));
        registry.check(address(module1), ModuleType.wrap(2));
        vm.expectRevert();
        registry.check(address(module1), ModuleType.wrap(3));
    }

    function test_WhenSupplyingManyAttesters_ShouldBe4337Compliant(uint8 threshold, address[] memory attesters) public {
        vm.assume(threshold < attesters.length);
        vm.startMappingRecording();
        vm.startStateDiffRecording();

        test_WhenSupplyingManyAttesters(threshold, attesters);

        VmSafe.AccountAccess[] memory accesses = vm.stopAndReturnStateDiff();

        ERC4337SpecsParser.Entities memory entities = ERC4337SpecsParser.Entities({
            account: smartAccount1.addr,
            factory: address(0),
            isFactoryStaked: false,
            paymaster: address(0),
            isPaymasterStaked: false,
            aggregator: address(0),
            isAggregatorStaked: false
        });

        for (uint256 i; i < accesses.length; i++) {
            VmSafe.AccountAccess memory currentAccess = accesses[i];
            if (currentAccess.account != address(this) && currentAccess.accessor != address(this)) {
                currentAccess.validateBannedStorageLocations(entities);
            }
        }

        vm.stopMappingRecording();
    }
}
