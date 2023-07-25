// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

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

    // function register(bytes32 schemaId, address moduleAddress, bytes calldata data) external;
}
