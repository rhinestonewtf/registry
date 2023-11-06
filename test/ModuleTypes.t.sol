// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "../src/lib/ModuleTypeLib.sol";

contract Jump {
    function enc(uint8[] calldata types) public view {
        ModuleTypeLib.encType(types);
    }
}

contract ModuleTypeTest is Test {
    Jump t;

    function setUp() public {
        t = new Jump();
    }

    function testEmptyModuleTypeArray__ShouldRevert() public {
        uint8[] memory moduleTypes = new uint8[](0);
        vm.expectRevert();
        t.enc(moduleTypes);
    }

    function testNonPrime__ShouldRevert() public {
        uint8[] memory moduleTypes = new uint8[](3);
        moduleTypes[0] = 2;
        moduleTypes[1] = 3;
        moduleTypes[2] = 4;
        vm.expectRevert();
        t.enc(moduleTypes);
    }

    function testOneEmpty__ShouldRevert() public {
        uint8[] memory moduleTypes = new uint8[](3);
        moduleTypes[0] = 2;
        moduleTypes[1] = 0;
        moduleTypes[2] = 5;
        vm.expectRevert();
        t.enc(moduleTypes);
    }
}
