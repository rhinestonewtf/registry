// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { PackedModuleTypes, ModuleType } from "../DataTypes.sol";
import { IRegistry } from "../IRegistry.sol";

library ModuleTypeLib {
    function isType(PackedModuleTypes self, ModuleType moduleType) internal pure returns (bool) {
        return (PackedModuleTypes.unwrap(self) & 2 ** ModuleType.unwrap(moduleType)) != 0;
    }

    function pack(ModuleType[] calldata moduleTypes) internal pure returns (PackedModuleTypes) {
        uint32 result;
        for (uint256 i; i < moduleTypes.length; i++) {
            uint32 _type = ModuleType.unwrap(moduleTypes[i]);
            if (_type > 31) revert IRegistry.InvalidModuleType();
            result = result + uint32(2 ** _type);
        }
        return PackedModuleTypes.wrap(result);
    }
}
