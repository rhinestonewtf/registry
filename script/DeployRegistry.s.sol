// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/RhinestoneRegistry.sol";
import "../test/utils/BaseUtils.sol";

/// @title DeployRegistryScript
/// @author zeroknots
contract DeployRegistryScript is Script, RegistryTestTools {
    function run() public {
        HashiEnv memory hashiEnv = _setupHashi(address(123));
        RegistryInstance memory instance = _setupInstance({
            name: "RegistryL1",
            yaho: hashiEnv.yaho,
            yaru: Yaru(address(0)),
            l1Registry: address(0)
        });

        vm.broadcast(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
        console2.log("DeployRegistryScript: registry address: %s", address(instance.registry));
    }
}
