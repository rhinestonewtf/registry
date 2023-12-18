// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { DeployRegistryScript } from "../../script/DeployRegistry.s.sol";
import { ISchema } from "../../src/interface/ISchema.sol";
import { ResolverRecord, ResolverUID } from "../../src/DataTypes.sol";

/// @title DeployRegistryTest
/// @author kopy-kat
contract DeployRegistryTest is Test {
    DeployRegistryScript script;

    function setUp() public {
        script = new DeployRegistryScript();
    }

    function testRun() public {
        script.run();
    }
}
