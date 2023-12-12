// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ModuleTypesEnc, ModuleType, ModuleTypeLib } from "src/DataTypes.sol";

contract ModuleTypeEncoding {
    function encodeModuleType(ModuleType[] calldata moduleTypes)
        public
        pure
        returns (ModuleTypesEnc)
    {
        return ModuleTypeLib.bitEncodeCalldata(moduleTypes);
    }
}
