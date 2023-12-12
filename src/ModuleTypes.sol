type ModuleTypesEnc is uint16;

type ModuleType is uint16;

ModuleType constant MODULE_TYPE_EXECUTOR = ModuleType.wrap(1);
ModuleType constant MODULE_TYPE_VALIDATOR = ModuleType.wrap(2);
ModuleType constant MODULE_TYPE_HOOK = ModuleType.wrap(4);
ModuleType constant MODULE_TYPE_PLACEHOLDER = ModuleType.wrap(8);

library ModuleTypeLib {
    function isType(ModuleTypesEnc self, ModuleType moduleType) internal pure returns (bool) {
        return (ModuleTypesEnc.unwrap(self) & ModuleType.unwrap(moduleType)) != 0;
    }

    function bitEncode(ModuleType[] memory moduleTypes) internal pure returns (ModuleTypesEnc) {
        uint16 result;
        for (uint256 i; i < moduleTypes.length; i++) {
            result = result + ModuleType.unwrap(moduleTypes[i]);
        }
        return ModuleTypesEnc.wrap(result);
    }
}
