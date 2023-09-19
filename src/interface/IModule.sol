// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ResolverUID } from "../DataTypes.sol";

interface IModule {
    // Event triggered when a contract is deployed.
    event ModuleRegistration(address indexed implementation, bytes32 resolver);
    event ModuleDeployed(address indexed implementation, bytes32 indexed salt, bytes32 resolver);
    event ModuleDeployedExternalFactory(
        address indexed implementation, address indexed factory, bytes32 resolver
    );

    error AlreadyRegistered(address module);

    error InvalidDeployment();

    /**
     * @notice Deploys a new module.
     *
     * @dev Ensures the resolver is valid and then deploys the module.
     *
     * @param code The bytecode for the module.
     * @param deployParams Parameters required for deployment.
     * @param salt Salt for creating the address.
     * @param data Data associated with the module.
     * @param resolverUID Unique ID of the resolver.
     *
     * @return moduleAddr The address of the deployed module.
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata data,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr);

    /**
     * @notice Deploys a new module using the CREATE3 method.
     *
     * @dev Similar to the deploy function but uses CREATE3 for deployment.
     * @dev the salt supplied here will be hashed again with msg.sender
     *
     * @param code The bytecode for the module.
     * @param deployParams Parameters required for deployment.
     * @param salt Initial salt for creating the final salt.
     * @param data Data associated with the module.
     * @param resolverUID Unique ID of the resolver.
     *
     * @return moduleAddr The address of the deployed module.
     */
    function deployC3(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata data,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr);

    /**
     * @notice Deploys a new module via an external factory contract.
     *
     * @param factory Address of the factory contract.
     * @param callOnFactory Encoded call to be made on the factory contract.
     * @param data Data associated with the module.
     * @param resolverUID Unique ID of the resolver.
     *
     * @return moduleAddr The address of the deployed module.
     */
    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata data,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr);

    /**
     * @notice Registers an existing module with the contract.
     *
     * @param resolverUID Unique ID of the resolver.
     * @param moduleAddress Address of the module.
     * @param data Data associated with the module.
     */
    function register(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata data
    )
        external;
}
