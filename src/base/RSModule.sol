// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IRSModule } from "../interface/IRSModule.sol";
import { InvalidSchema } from "../Common.sol";
import { RSModuleDeploymentLib } from "../lib/RSModuleDeploymentLib.sol";
import { IRSSchema, SchemaRecord } from "../interface/IRSSchema.sol";
import { RSSchema } from "./RSSchema.sol";
import { ISchemaResolver } from "../resolver/ISchemaResolver.sol";
import { Attestation, Module } from "../Common.sol";

/**
 * @title RSModule
 *
 * @dev The RSModule contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IRSModule interface and the RSSchema contract,
 * providing the actual implementation for the interface and extending the functionality of the RSSchema contract.
 *
 * @dev The primary responsibility of the RSModule is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the RSModule. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional data are stored in a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev The `deploy` function is used to deploy a new module. The code of the module, parameters for deployment (constructor arguments),
 * a salt for creating the contract, additional data for registration, and a schema ID under which to register the contract are
 * all passed as arguments to this function. This function first checks if the provided schema ID is valid and then deploys the contract.
 * Once the contract is successfully deployed, the details are stored in the `_modules` mapping and a `Deployment` event is emitted.
 *
 * @dev Furthermore, the RSModule contract utilizes the Ethereum `CREATE2` opcode in its `_deploy` function for deploying
 * contracts. This opcode allows creating a contract with a deterministic address, which is calculated in the `_calcAddress` function.
 * This approach provides flexibility and advanced patterns in contract interactions, like the ability to show a contract’s address
 * before it is mined.
 *
 * @dev In conclusion, the RSModule is a central part of a system to manage, deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 */
abstract contract RSModule is IRSModule {
    mapping(address moduleAddress => Module) internal _modules;

    using RSModuleDeploymentLib for bytes;
    using RSModuleDeploymentLib for address;

    error AlreadyRegistered(address module);

    /**
     * @inheritdoc IRSModule
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data,
        bytes32 schemaId
    )
        external
        returns (address moduleAddr)
    {
        // Check if the provided schemaId exists
        SchemaRecord memory schema = getSchema(schemaId);
        if (schemaId != schema.uid) revert InvalidSchema();

        bytes32 contractCodeHash; //  Hash of contract bytecode
        bytes32 deployParamsHash; // Hash of contract deployment parameters
        (moduleAddr, deployParamsHash, contractCodeHash) = code.deploy(deployParams, salt);

        _register(moduleAddr, msg.sender, schema, contractCodeHash, deployParamsHash, data);

        emit ModuleRegistration(moduleAddr, contractCodeHash); // Emit a deployment event
    }

    // this function might be removed in the future.
    // could be a security risk
    // TODO
    function register(bytes32 schemaId, address moduleAddress, bytes calldata data) external {
        // Check if the provided schemaId exists
        SchemaRecord memory schema = getSchema(schemaId);
        if (schemaId != schema.uid) revert InvalidSchema();

        // get codehash of depoyed contract
        bytes32 contractCodeHash = moduleAddress.codeHash();
        _register(moduleAddress, address(0), schema, contractCodeHash, "", data);

        emit ModuleRegistration(moduleAddress, contractCodeHash); // Emit a registration event
    }

    function _register(
        address moduleAddress,
        address sender,
        SchemaRecord memory schema,
        bytes32 codeHash,
        bytes32 deployParamsHash,
        bytes calldata data
    )
        private
    {
        // ensure moduleAddress is not already registered
        if (_modules[moduleAddress].implementation != address(0)) {
            revert AlreadyRegistered(moduleAddress);
        }
        // Store module data in _modules mapping
        Module memory moduleRegistration = Module({
            implementation: moduleAddress,
            codeHash: codeHash,
            deployParamsHash: deployParamsHash,
            schemaId: schema.uid,
            sender: sender,
            data: data
        });

        _resolveRegistration(schema.resolver, moduleRegistration);

        _modules[moduleAddress] = moduleRegistration;
    }

    function _resolveRegistration(
        ISchemaResolver resolver,
        Module memory moduleRegistration
    )
        private
    {
        if (address(resolver) == address(0)) return;
        if (resolver.moduleRegistration(moduleRegistration) == false) revert InvalidDeployment();
    }

    function getSchema(bytes32 uid) public view virtual returns (SchemaRecord memory);

    function _getModule(address moduleAddress) internal view virtual returns (Module storage) {
        return _modules[moduleAddress];
    }
}
