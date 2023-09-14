// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IModule } from "../interface/IModule.sol";
import { InvalidResolver } from "../Common.sol";
import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import { ISchema, SchemaRecord, SchemaResolver } from "../interface/ISchema.sol";
import { Schema } from "./Schema.sol";
import { AttestationRecord, ModuleRecord } from "../Common.sol";
import { ISchemaValidator } from "../resolver/ISchemaValidator.sol";
import { ISchemaResolver } from "../resolver/ISchemaResolver.sol";

/**
 * @title Module
 *
 * @dev The Module contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IModule interface and the Schema contract,
 * providing the actual implementation for the interface and extending the functionality of the Schema contract.
 *
 * @dev The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the Module. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional data are stored in a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev The `deploy` function is used to deploy a new module. The code of the module, parameters for deployment (constructor arguments),
 * a salt for creating the contract, additional data for registration, and a schema ID under which to register the contract are
 * all passed as arguments to this function. This function first checks if the provided schema ID is valid and then deploys the contract.
 * Once the contract is successfully deployed, the details are stored in the `_modules` mapping and a `Deployment` event is emitted.
 *
 * @dev Furthermore, the Module contract utilizes the Ethereum `CREATE2` opcode in its `_deploy` function for deploying
 * contracts. This opcode allows creating a contract with a deterministic address, which is calculated in the `_calcAddress` function.
 * This approach provides flexibility and advanced patterns in contract interactions, like the ability to show a contract’s address
 * before it is mined.
 *
 * @dev In conclusion, the Module is a central part of a system to manage, deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 */
abstract contract Module is IModule {
    mapping(address moduleAddress => ModuleRecord) internal _modules;

    using ModuleDeploymentLib for bytes;
    using ModuleDeploymentLib for address;

    error AlreadyRegistered(address module);

    /**
     * @inheritdoc IModule
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data,
        bytes32 referrerUID
    )
        external
        payable
        returns (address moduleAddr)
    {
        // Check if the provided schemaId exists
        SchemaResolver memory resolver = getSchemaResolver(referrerUID);
        if (resolver.schemaOwner == address(0)) revert InvalidResolver();

        bytes32 contractCodeHash; //  Hash of contract bytecode
        bytes32 deployParamsHash; // Hash of contract deployment parameters
        (moduleAddr, deployParamsHash, contractCodeHash) =
            code.deploy(deployParams, salt, msg.value);

        _register(
            moduleAddr, msg.sender, resolver, referrerUID, contractCodeHash, deployParamsHash, data
        );

        emit ModuleRegistration(moduleAddr, contractCodeHash); // Emit a deployment event
    }

    // this function might be removed in the future.
    // could be a security risk
    // TODO
    function register(bytes32 referrerUID, address moduleAddress, bytes calldata data) external {
        // Check if the provided schemaId exists
        SchemaResolver memory resolver = getSchemaResolver(referrerUID);
        if (resolver.schemaOwner == address(0)) revert InvalidResolver();

        // get codehash of depoyed contract
        bytes32 contractCodeHash = moduleAddress.codeHash();
        _register(moduleAddress, address(0), resolver, referrerUID, contractCodeHash, "", data);

        emit ModuleRegistration(moduleAddress, contractCodeHash); // Emit a registration event
    }

    function _register(
        address moduleAddress,
        address sender,
        SchemaResolver memory referrer,
        bytes32 resolverUID,
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
        ModuleRecord memory moduleRegistration = ModuleRecord({
            implementation: moduleAddress,
            resolverUID: resolverUID,
            sender: sender,
            data: data
        });

        _resolveRegistration(referrer.resolver, moduleRegistration);

        _modules[moduleAddress] = moduleRegistration;
    }

    function _resolveRegistration(
        ISchemaResolver resolver,
        ModuleRecord memory moduleRegistration
    )
        private
    {
        if (address(resolver) == address(0)) return;
        if (resolver.moduleRegistration(moduleRegistration) == false) {
            revert InvalidDeployment();
        }
    }

    function getSchemaResolver(bytes32 uid) public view virtual returns (SchemaResolver memory);

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        returns (ModuleRecord storage)
    {
        return _modules[moduleAddress];
    }
}
