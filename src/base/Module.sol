// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IModule } from "../interface/IModule.sol";
import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import { CREATE3 } from "solady/src/utils/CREATE3.sol";
import { ISchema } from "../interface/ISchema.sol";
import { IRegistry } from "../interface/IRegistry.sol";
import { Schema } from "./Schema.sol";
import "../DataTypes.sol";
import { InvalidResolver, _isContract } from "../Common.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";
import { IResolver } from "../external/IResolver.sol";

/**
 * @title Module
 *
 * @dev The Module contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IModule interface
 *
 * @dev The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the Module. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional data are stored in a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev In conclusion, the Module is a central part of a system to manage, deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 */
abstract contract Module is IModule {
    using ModuleDeploymentLib for bytes;
    using ModuleDeploymentLib for address;

    mapping(address moduleAddress => ModuleRecord) private _modules;

    /**
     * @inheritdoc IModule
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr)
    {
        // Check if the provided schemaId exists
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == address(0)) revert InvalidResolver();

        (moduleAddr,,) = code.deploy(deployParams, salt, msg.value);

        _register(moduleAddr, msg.sender, resolver, resolverUID, data);
    }

    function deployC3(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata data,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == address(0)) revert InvalidResolver();
        bytes memory creationCode = abi.encodePacked(code, deployParams);
        moduleAddr = CREATE3.deploy(salt, creationCode, msg.value);

        _register(moduleAddr, msg.sender, resolver, resolverUID, data);
    }

    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata data,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == address(0)) revert InvalidResolver();
        (bool ok, bytes memory returnData) = factory.call{ value: msg.value }(callOnFactory);

        if (!ok) revert InvalidDeployment();
        moduleAddr = abi.decode(returnData, (address));

        _register(moduleAddr, msg.sender, resolver, resolverUID, data);
    }

    function register(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata data
    )
        external
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.schemaOwner == address(0)) revert InvalidResolver();

        _register(moduleAddress, address(0), resolver, resolverUID, data);
    }

    function _register(
        address moduleAddress,
        address sender,
        ResolverRecord memory resolver,
        ResolverUID resolverUID,
        bytes calldata data
    )
        private
    {
        // ensure moduleAddress is not already registered
        if (_modules[moduleAddress].implementation != address(0)) {
            revert AlreadyRegistered(moduleAddress);
        }
        if (_isContract(moduleAddress) != true) {
            revert InvalidDeployment();
        }

        // Store module data in _modules mapping
        ModuleRecord memory moduleRegistration = ModuleRecord({
            implementation: moduleAddress,
            resolverUID: resolverUID,
            sender: sender,
            data: data
        });

        _resolveRegistration(resolver.resolver, moduleRegistration);

        _modules[moduleAddress] = moduleRegistration;
    }

    function _resolveRegistration(
        IResolver resolver,
        ModuleRecord memory moduleRegistration
    )
        private
    {
        if (address(resolver) == address(0)) return;
        if (resolver.moduleRegistration(moduleRegistration) == false) {
            revert InvalidDeployment();
        }
    }

    function getResolver(ResolverUID uid) public view virtual returns (ResolverRecord memory);

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        returns (ModuleRecord storage)
    {
        return _modules[moduleAddress];
    }

    function getModule(address moduleAddress) public view returns (ModuleRecord memory) {
        return _getModule(moduleAddress);
    }
}
