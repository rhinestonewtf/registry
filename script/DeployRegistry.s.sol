// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Registry.sol";
import "../test/utils/BaseUtils.sol";

/// @title DeployRegistryScript
/// @author zeroknots
contract DeployRegistryScript is Script, RegistryTestTools {
    function run() public {
        vm.startBroadcast(vm.envUint("PK"));
        RegistryInstance memory instance = _setupInstance({ name: "RegistryL1" });
        vm.stopBroadcast();
    }
}
