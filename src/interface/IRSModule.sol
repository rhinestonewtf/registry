// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IRSModule {
    enum RunLevel {
        STATICCALL,
        CALL,
        DELEGATECALL,
        PROXY,
        SAFEMODULE
    }

    function runLevel() external view returns (RunLevel);
    function version() external view returns (uint8);
}
