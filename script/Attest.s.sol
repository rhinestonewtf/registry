// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";
import { IRegistry } from "src/IRegistry.sol";
import { SchemaUID, AttestationRequest, ModuleType } from "src/DataTypes.sol";

contract Attest is Script {
    function run() public {
        IRegistry registry = IRegistry(0x000000000069E2a187AEFFb852bF3cCdC95151B2);

        SchemaUID schemaUID = SchemaUID.wrap(0x93d46fcca4ef7d66a413c7bde08bb1ff14bacbd04c4069bb24cd7c21729d7bf1);
        AttestationRequest[] memory attestations = new AttestationRequest[](7);

        ModuleType[] memory moduleTypesValidator = new ModuleType[](1);
        moduleTypesValidator[0] = ModuleType.wrap(1);
        attestations[0] = AttestationRequest({
            moduleAddress: address(0xDDFF43A42726df11E34123f747bDce0f755F784d),
            expirationTime: 0,
            data: hex"414141414141414141",
            moduleTypes: moduleTypesValidator
        });

        ModuleType[] memory moduleTypesPolicy = new ModuleType[](0);

        attestations[1] = AttestationRequest({
            moduleAddress: address(0x8E58f4945e6BA2A11B184A9c20B6C765a0891b95),
            expirationTime: 0,
            data: hex"414141414141414141",
            moduleTypes: moduleTypesPolicy
        });
        attestations[2] = AttestationRequest({
            moduleAddress: address(0x529Ad04F4D83aAb25144a90267D4a1443B84f5A6),
            expirationTime: 0,
            data: hex"414141414141414141",
            moduleTypes: moduleTypesPolicy
        });
        attestations[3] = AttestationRequest({
            moduleAddress: address(0x8177451511dE0577b911C254E9551D981C26dc72),
            expirationTime: 0,
            data: hex"414141414141414141",
            moduleTypes: moduleTypesPolicy
        });
        attestations[4] = AttestationRequest({
            moduleAddress: address(0x148CD6c24F4dd23C396E081bBc1aB1D92eeDe2BF),
            expirationTime: 0,
            data: hex"414141414141414141",
            moduleTypes: moduleTypesPolicy
        });
        attestations[5] = AttestationRequest({
            moduleAddress: address(0x1F34eF8311345A3A4a4566aF321b313052F51493),
            expirationTime: 0,
            data: hex"414141414141414141",
            moduleTypes: moduleTypesPolicy
        });
        attestations[6] = AttestationRequest({
            moduleAddress: address(0x730DA93267E7E513e932301B47F2ac7D062abC83),
            expirationTime: 0,
            data: hex"414141414141414141",
            moduleTypes: moduleTypesPolicy
        });

        vm.startBroadcast(vm.envUint("PK"));

        registry.attest(schemaUID, attestations);

        vm.stopBroadcast();
    }
}
