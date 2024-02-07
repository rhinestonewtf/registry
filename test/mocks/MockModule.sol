// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockModuleWithArgs {
    uint256 value;

    constructor(uint256 _value) {
        value = _value;
    }

    function readValue() public view returns (uint256) {
        return value;
    }
}

contract MockModule {
    function foo() public pure returns (uint256) {
        return 1;
    }
}
