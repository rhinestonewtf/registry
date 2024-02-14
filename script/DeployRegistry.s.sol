// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { IExternalResolver } from "../src/external/IExternalResolver.sol";
import { Registry } from "../src/Registry.sol";
import { ResolverUID } from "../src/DataTypes.sol";
import { console2 } from "forge-std/console2.sol";
import "./Create2Factory.sol";

/**
 * @title DeployRegistryScript
 * @author zeroknots
 */
contract DeployRegistryScript is Script {
    function run() public {
        bytes32 salt = 0x05a40beaf368eb6b2bc5665901a885c044c19346fc828ba80a35fe4cc30d0000;

        bytes memory initcode = type(Registry).creationCode;
        bytes32 initcodeHash = keccak256(initcode);
        console2.log("initcodeHash:");
        console2.logBytes32(initcodeHash);

        ImmutableCreate2Factory factory = new ImmutableCreate2Factory();
        bytes memory code = address(factory).code;

        vm.startBroadcast(vm.envUint("PK"));
        address factoryAddress = address(0x0000000000FFe8B47B3e2130213B802212439497);
        vm.etch(factoryAddress, code);
        factory = ImmutableCreate2Factory(factoryAddress);

        Registry registry = Registry(factory.safeCreate2(salt, initcode));

        console2.log("Deployed Registry @", address(registry));
    }
}
