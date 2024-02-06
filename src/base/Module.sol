// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";
import { CREATE3 } from "solady/utils/CREATE3.sol";

import { IModule } from "../interface/IModule.sol";

import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import { Schema } from "./Schema.sol";
import { IResolver } from "../external/IResolver.sol";

import { InvalidResolver, _isContract, ZERO_ADDRESS } from "../Common.sol";
import {
    ResolverRecord,
    ModuleRecord,
    ResolverUID,
    AttestationRequestData,
    RevocationRequestData
} from "../DataTypes.sol";

/**
 * @title Module
 *
 * @dev The Module contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IModule interface
 *
 * @dev The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the Module. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional metadata are stored in a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev In conclusion, the Module is a central part of a system to manage, deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract Module is IModule, ReentrancyGuard {
    using ModuleDeploymentLib for bytes;
    using ModuleDeploymentLib for address;

    mapping(address moduleAddress => ModuleRecord) private _modules;

    /**
     * @inheritdoc IModule
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        nonReentrant
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver();

        (moduleAddr,,) = code.deploy(deployParams, salt, msg.value);

        _register({
            moduleAddress: moduleAddr,
            sender: msg.sender,
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
    }

    /**
     * @inheritdoc IModule
     */
    function deployC3(
        bytes calldata code,
        bytes calldata deployParams,
        bytes32 salt,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        nonReentrant
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver();
        bytes memory creationCode = abi.encodePacked(code, deployParams);
        bytes32 senderSalt = keccak256(abi.encodePacked(salt, msg.sender));
        moduleAddr = CREATE3.deploy(senderSalt, creationCode, msg.value);

        _register({
            moduleAddress: moduleAddr,
            sender: msg.sender,
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
    }

    /**
     * @inheritdoc IModule
     */
    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        nonReentrant
        returns (address moduleAddr)
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver();
        (bool ok, bytes memory returnData) = factory.call{ value: msg.value }(callOnFactory);

        if (!ok) revert InvalidDeployment();
        moduleAddr = abi.decode(returnData, (address));
        if (moduleAddr == ZERO_ADDRESS) revert InvalidDeployment();
        if (_isContract(moduleAddr) != true) revert InvalidDeployment();

        _register({
            moduleAddress: moduleAddr,
            sender: msg.sender,
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
    }

    /**
     * @inheritdoc IModule
     */
    function register(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata
    )
        external
        nonReentrant
    {
        ResolverRecord memory resolver = getResolver(resolverUID);
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver();

        _register({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolver: resolver,
            resolverUID: resolverUID,
            metadata: metadata
        });
    }

    /**
     * @dev Registers a module, ensuring it's not already registered.
     *  This function ensures that the module is a contract.
     *  Also ensures that moduleAddress is not ZERO_ADDRESS.
     *
     * @param moduleAddress Address of the module.
     * @param sender Address of the sender registering the module.
     * @param resolver Resolver record associated with the module.
     * @param resolverUID Unique ID of the resolver.
     * @param metadata Data associated with the module.
     */
    function _register(
        address moduleAddress,
        address sender,
        ResolverRecord memory resolver,
        ResolverUID resolverUID,
        bytes calldata metadata
    )
        private
    {
        // ensure moduleAddress is not already registered
        if (_modules[moduleAddress].implementation != ZERO_ADDRESS) {
            revert AlreadyRegistered(moduleAddress);
        }
        // revert if moduleAddress is NOT a contract
        if (!_isContract(moduleAddress)) revert InvalidDeployment();

        // Store module metadata in _modules mapping
        ModuleRecord memory moduleRegistration = ModuleRecord({
            implementation: moduleAddress,
            resolverUID: resolverUID,
            sender: sender,
            metadata: metadata
        });

        // Resolve module registration using resolver
        _resolveRegistration({
            resolverContract: resolver.resolver,
            moduleRegistration: moduleRegistration
        });

        // Store module record in _modules mapping
        _modules[moduleAddress] = moduleRegistration;

        // Emit ModuleRegistration event
        emit ModuleRegistration(moduleAddress, sender, ResolverUID.unwrap(resolverUID));
    }

    /**
     * @dev Resolves the module registration using the provided resolver.
     *
     * @param resolverContract Resolver to validate the module registration.
     * @param moduleRegistration Module record to be registered.
     */
    function _resolveRegistration(
        IResolver resolverContract,
        ModuleRecord memory moduleRegistration
    )
        private
    {
        if (address(resolverContract) == ZERO_ADDRESS) return;
        if (resolverContract.moduleRegistration(moduleRegistration) == false) {
            revert InvalidDeployment();
        }
    }

    /**
     * @notice Retrieves the resolver record for a given UID.
     *
     * @param uid The UID of the resolver to retrieve.
     *
     * @return The resolver record associated with the given UID.
     */
    function getResolver(ResolverUID uid) public view virtual returns (ResolverRecord memory);

    /**
     * @dev Retrieves the module record for a given address.
     *
     * @param moduleAddress The address of the module to retrieve.
     *
     * @return moduleRecord The module record associated with the given address.
     */
    function _getModule(address moduleAddress)
        internal
        view
        virtual
        returns (ModuleRecord storage)
    {
        return _modules[moduleAddress];
    }

    /**
     * @notice Retrieves the module record for a given address.
     *
     * @param moduleAddress The address of the module to retrieve.
     *
     * @return moduleRecord The module record associated with the given address.
     */
    function getModule(address moduleAddress) public view returns (ModuleRecord memory) {
        return _getModule(moduleAddress);
    }
}
