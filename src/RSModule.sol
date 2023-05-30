// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interface/IRSModule.sol";

/// @title RSModule
/// @author zeroknots
/// @notice Template of RSModule

contract RSModule is IRSModule {
    RunLevel public constant runLevel = RunLevel.CALL;
    uint8 public constant version = 1;
}
