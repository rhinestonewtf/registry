// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import { PackedModuleTypes, ModuleType } from "../DataTypes.sol";
import { IRegistry } from "../IRegistry.sol";

library ModuleTypeLib {
    function isType(PackedModuleTypes self, ModuleType moduleType) internal pure returns (bool) {
        return (PackedModuleTypes.unwrap(self) & 2 ** ModuleType.unwrap(moduleType)) != 0;
    }

    function isType(uint32 packed, uint256 check) internal pure returns (bool) {
        return (packed & 2 ** check) != 0;
    }

    function pack(ModuleType[] memory moduleTypes) internal pure returns (PackedModuleTypes) {
        uint256 length = moduleTypes.length;
        uint32 packed;
        uint256 _type;
        for (uint256 i; i < length; i++) {
            _type = ModuleType.unwrap(moduleTypes[i]);
            if (_type > 31 || isType(packed, _type)) revert IRegistry.InvalidModuleType();
            packed = packed + uint32(2 ** _type);
        }
        return PackedModuleTypes.wrap(packed);
    }
}
