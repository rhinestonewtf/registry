// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Struct that represents a contract artifact.
struct Module {
    address implementation;
    bytes32 codeHash;
    bytes32 deployParamsHash;
    bytes32 schemaId;
    address sender;
    bytes data;
}

interface IRSModuleRegistry {
    // Event triggered when a contract is deployed.
    event Deployment(address indexed implementation, bytes32 codeHash);

    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data,
        bytes32 schemaId
    )
        external
        returns (address moduleAddr);
}
