// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { CREATE3 } from "solady/utils/CREATE3.sol";

import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import { StubLib } from "../lib/StubLib.sol";
import { IExternalResolver } from "../external/IExternalResolver.sol";

import { InvalidResolver, _isContract, EMPTY_RESOLVER_UID, ZERO_ADDRESS } from "../Common.sol";
import { ResolverRecord, ModuleRecord, ResolverUID } from "../DataTypes.sol";
import { ResolverManager } from "./ResolverManager.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * @title Module
 *
 * @dev The Module contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IModule interface
 *
 * @dev The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the Module. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional metadata are stored in
 *        a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev In conclusion, the Module is a central part of a system to manage,
 *    deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract ModuleManager is IRegistry, ResolverManager {
    using ModuleDeploymentLib for bytes;
    using ModuleDeploymentLib for address;
    using StubLib for *;

    mapping(address moduleAddress => ModuleRecord moduleRecord) internal _modules;

    function deploy(
        bytes32 salt,
        ResolverUID resolverUID,
        bytes calldata code,
        bytes calldata deployParams,
        bytes calldata metadata
    )
        external
        payable
        returns (address moduleAddr)
    {
        ResolverRecord storage resolver = resolvers[resolverUID];
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver();

        // address predictedModuleAddress = code.calculateAddress(deployParams, salt);

        (moduleAddr,,) = code.deploy(deployParams, salt, msg.value);
        // _storeModuleRecord() will check if module is already registered,
        // which should prevent reentry to any deploy function
        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddr, // TODO: is this reentrancy?
            sender: msg.sender,
            resolverUID: resolverUID,
            metadata: metadata
        });
        record.requireExternalResolverCheck(resolver);
    }

    function register(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata
    )
        external
    {
        ResolverRecord storage resolver = resolvers[resolverUID];
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver();

        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolverUID: resolverUID,
            metadata: metadata
        });
        record.requireExternalResolverCheck(resolver);
    }

    function _storeModuleRecord(
        address moduleAddress,
        address sender,
        ResolverUID resolverUID,
        bytes calldata metadata
    )
        internal
        returns (ModuleRecord memory moduleRegistration)
    {
        // ensure that non-zero resolverUID was provided
        if (resolverUID == EMPTY_RESOLVER_UID) revert InvalidDeployment();
        // ensure moduleAddress is not already registered
        if (_modules[moduleAddress].resolverUID != EMPTY_RESOLVER_UID) {
            revert AlreadyRegistered(moduleAddress);
        }
        // revert if moduleAddress is NOT a contract
        if (!_isContract(moduleAddress)) revert InvalidDeployment();

        // Store module metadata in _modules mapping
        moduleRegistration =
            ModuleRecord({ resolverUID: resolverUID, sender: sender, metadata: metadata });

        // Store module record in _modules mapping
        _modules[moduleAddress] = moduleRegistration;

        // Emit ModuleRegistration event
        emit ModuleRegistration(moduleAddress, sender, ResolverUID.unwrap(resolverUID));
    }
}
