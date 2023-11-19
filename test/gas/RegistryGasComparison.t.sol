// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { console2 } from "forge-std/console2.sol";
import { BaseTest, RegistryTestLib, RegistryInstance } from "../utils/BaseTest.t.sol";
import { IERC7484 } from "../../src/interface/IERC7484.sol";

contract Minimal7484Registry is IERC7484 {
    mapping(address module => uint256) public modules;

    function check(address module, address) public view returns (uint256 attestedAt) {
        attestedAt = modules[module];
        require(attestedAt > 0, "Module not registered");
    }

    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray)
    {
        // unused
    }

    function attest(address module) public {
        modules[module] = 123_456;
    }
}

contract RegistryGasComparisonTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    address minimal7484Registry1 = address(new Minimal7484Registry());
    address minimal7484Registry2 = address(new Minimal7484Registry());
    address minimal7484Registry3 = address(new Minimal7484Registry());

    address firstAttester;
    address secondAttester;
    address thirdAttester;

    function setUp() public override {
        super.setUp();
        vm.warp(0x567654567);

        Minimal7484Registry(minimal7484Registry1).attest(defaultModule1);
        Minimal7484Registry(minimal7484Registry2).attest(defaultModule1);
        Minimal7484Registry(minimal7484Registry3).attest(defaultModule1);

        (address _firstAttester, uint256 firstKey) = makeAddrAndKey("firstAttester");
        firstAttester = _firstAttester;

        (address _secondAttester, uint256 secondKey) = makeAddrAndKey("secondAttester");
        secondAttester = _secondAttester;

        (address _thirdAttester, uint256 thirdKey) = makeAddrAndKey("thirdAttester");
        thirdAttester = _thirdAttester;

        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, firstKey);
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, secondKey);
        instance.mockDelegatedAttestation(defaultSchema1, defaultModule1, thirdKey);
    }

    function testGasCheck() public {
        address module = defaultModule1;

        // treat as immutable
        address rhinestoneRegistry = address(instance.registry);

        rhinestoneRegistry.call(
            abi.encodeWithSignature(
                "function mock(address module, address attester) public", module, firstAttester
            )
        );

        uint256 gasCheck = gasleft();
        uint256 attestedAt = IERC7484(rhinestoneRegistry).check(module, firstAttester);
        gasCheck = gasCheck - gasleft() - 10;

        uint256 gasCheckMinimal7484 = gasleft();
        uint256 attestedAtMinimal = IERC7484(minimal7484Registry1).check(module, address(0));
        gasCheckMinimal7484 = gasCheckMinimal7484 - gasleft() - 10;

        console2.log("Rhinestone Registry check: %s", gasCheck);
        console2.log("Minimal 7484 Registry check: %s", gasCheckMinimal7484);
    }

    function testGasCheckN__Given__TwoAttesters() public {
        address module = defaultModule1;

        // treat as immutable
        address rhinestoneRegistry = address(instance.registry);

        uint256 gasCheck = gasleft();
        address[] memory attesters = new address[](2);
        attesters[0] = firstAttester;
        attesters[1] = secondAttester;
        uint256[] memory attestedAtArray = IERC7484(rhinestoneRegistry).checkN(module, attesters, 2);
        gasCheck = gasCheck - gasleft() - 10;

        uint256 gasCheckMinimal7484 = gasleft();
        uint256 attestedAtMinimal = IERC7484(minimal7484Registry1).check(module, address(0));
        uint256 attestedAtMinimal2 = IERC7484(minimal7484Registry2).check(module, address(0));
        gasCheckMinimal7484 = gasCheckMinimal7484 - gasleft() - 10;

        console2.log("Rhinestone Registry checkN (2): %s", gasCheck);
        console2.log("Minimal 7484 Registry check (2): %s", gasCheckMinimal7484);
    }

    function testGasCheckN__Given__ThreeAttesters() public {
        address module = defaultModule1;

        // treat as immutable
        address rhinestoneRegistry = address(instance.registry);

        uint256 gasCheck = gasleft();
        address[] memory attesters = new address[](3);
        attesters[0] = firstAttester;
        attesters[1] = secondAttester;
        attesters[2] = thirdAttester;
        uint256[] memory attestedAtArray = IERC7484(rhinestoneRegistry).checkN(module, attesters, 3);
        gasCheck = gasCheck - gasleft() - 10;

        uint256 gasCheckMinimal7484 = gasleft();
        uint256 attestedAtMinimal = IERC7484(minimal7484Registry1).check(module, address(0));
        uint256 attestedAtMinimal2 = IERC7484(minimal7484Registry2).check(module, address(0));
        uint256 attestedAtMinimal3 = IERC7484(minimal7484Registry3).check(module, address(0));
        gasCheckMinimal7484 = gasCheckMinimal7484 - gasleft() - 10;

        console2.log("Rhinestone Registry checkN (3): %s", gasCheck);
        console2.log("Minimal 7484 Registry check (3): %s", gasCheckMinimal7484);
    }
}
