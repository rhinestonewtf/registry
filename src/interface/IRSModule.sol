// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Struct that represents a contract artifact.
struct Module {
    address implementation; // The deployed contract address
    bytes32 codeHash; // The hash of the contract code
    bytes32 deployParamsHash; // The hash of the parameters used to deploy the contract
    bytes32 schemaId; // The id of the schema related to this module
    address sender; // The address of the sender who deployed the contract
    bytes data; // Additional data related to the contract deployment
}

interface IRSModule {
    // Event triggered when a contract is deployed.
    event ModuleRegistration(address indexed implementation, bytes32 codeHash);
    // Error to throw if the deployment is invalid

    error InvalidDeployment();

    /**
     * @dev Deploys a Module and registers it in the registry.
     *
     * param code The creationCode for the contract to be deployed.
     * @param deployParams abi.encode() params supplied for constructor of contract
     * @param salt The salt for creating the contract.
     * @param data additonal data provided for registration
     * @return moduleAddr The address of the deployed contract.
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data,
        bytes32 schemaId
    )
        external
        returns (address moduleAddr);

    function register(bytes32 schemaId, address moduleAddress, bytes calldata data) external;
}
