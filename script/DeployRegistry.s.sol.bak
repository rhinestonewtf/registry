// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Script } from "forge-std/Script.sol";
import { RegistryTestTools, RegistryInstance } from "../test/utils/BaseUtils.sol";
import { DebugResolver } from "../src/external/examples/DebugResolver.sol";
import { IResolver } from "../src/external/IResolver.sol";
import { ResolverUID } from "../src/DataTypes.sol";
import { console2 } from "forge-std/console2.sol";

/**
 * @title DeployRegistryScript
 * @author zeroknots
 */
contract DeployRegistryScript is Script, RegistryTestTools {
    function run() public {
        bytes32 salt = bytes32(uint256(2));

        vm.startBroadcast(vm.envUint("PK"));

        // Deploy Registry
        RegistryInstance memory instance = _setupInstance({ name: "Registry", salt: salt });

        // Set up default resolver
        DebugResolver debugResolver = new DebugResolver{ salt: salt }(address(instance.registry));
        instance.registry.registerResolver(IResolver(address(debugResolver)));

        vm.stopBroadcast();
    }
}
