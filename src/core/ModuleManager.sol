// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import { StubLib } from "../lib/StubLib.sol";

import { _isContract, EMPTY_RESOLVER_UID, ZERO_ADDRESS } from "../Common.sol";
import { ResolverRecord, ModuleRecord, ResolverUID } from "../DataTypes.sol";
import { ResolverManager } from "./ResolverManager.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * In order to separate msg.sender context from registry,
 * interactions with external Factories are done with this Trampoline contract.
 */
contract FactoryTrampoline {
    error FactoryCallFailed(address factory);

    /**
     * @param factory the address of the factory to call
     * @param callOnFactory the call data to send to the factory
     * @return moduleAddress the moduleAddress that was returned by the
     */
    function deployViaFactory(address factory, bytes memory callOnFactory) external payable returns (address moduleAddress) {
        // call external factory to deploy module
        bool success;
        /* solhint-disable no-inline-assembly */
        assembly ("memory-safe") {
            success := call(gas(), factory, callvalue(), add(callOnFactory, 0x20), mload(callOnFactory), 0, 32)
            moduleAddress := mload(0)
        }
        if (!success) {
            revert FactoryCallFailed(factory);
        }
    }
}

/**
 * In order for Attesters to be able to make statements about a Module, the Module first needs to be registered on the Registry.
 * This can be done as part of or after Module deployment. On registration, every module is tied to a
 * [ResolverManager](../ModuleManager.sol/abstract.ResolverManager.html) that is triggered on certain registry actions.
 *
 * The ModuleManager contract is responsible for handling module the registration,
 *           storage and retrieval of modules on the Registry.
 *           This contract inherits from the `IModule` interface
 * The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the Module. The details of each module, such as its address, resolver UID
 * sender address, deploy parameters hash, and additional metadata are stored in
 *        a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 * @dev The module developer select the resolver to be used for attestations and revocations made of the module.
 *    @dev Important: only module registrations made through the `deployModule()`  function are frontrun protected.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract ModuleManager is IRegistry, ResolverManager {
    using ModuleDeploymentLib for bytes;
    using ModuleDeploymentLib for address;
    using StubLib for *;

    mapping(address moduleAddress => ModuleRecord moduleRecord) internal $moduleAddrToRecords;

    FactoryTrampoline private immutable FACTORY_TRAMPOLINE;

    constructor() {
        FACTORY_TRAMPOLINE = new FactoryTrampoline();
    }

    /**
     * @inheritdoc IRegistry
     */
    function deployModule(
        bytes32 salt,
        ResolverUID resolverUID,
        bytes calldata initCode,
        bytes calldata metadata,
        bytes calldata resolverContext
    )
        external
        payable
        returns (address moduleAddress)
    {
        ResolverRecord storage $resolver = $resolvers[resolverUID];
        if ($resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolverUID(resolverUID);

        moduleAddress = initCode.deploy(salt);
        // _storeModuleRecord() will check if module is already registered,
        // which should prevent reentry to any deploy function
        ModuleRecord memory record =
            _storeModuleRecord({ moduleAddress: moduleAddress, sender: msg.sender, resolverUID: resolverUID, metadata: metadata });

        record.requireExternalResolverOnModuleRegistration({
            moduleAddress: moduleAddress,
            $resolver: $resolver,
            resolverContext: resolverContext
        });
    }

    /**
     * @inheritdoc IRegistry
     */
    function calcModuleAddress(bytes32 salt, bytes calldata initCode) external view returns (address) {
        return initCode.calcAddress(salt);
    }

    /**
     * @inheritdoc IRegistry
     */
    function registerModule(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata,
        bytes calldata resolverContext
    )
        external
    {
        ResolverRecord storage $resolver = $resolvers[resolverUID];

        // ensure that non-zero resolverUID was provided
        if ($resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolverUID(resolverUID);

        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolverUID: resolverUID,
            metadata: metadata
        });

        // resolve module registration
        record.requireExternalResolverOnModuleRegistration({
            moduleAddress: moduleAddress,
            $resolver: $resolver,
            resolverContext: resolverContext
        });
    }

    /**
     * @inheritdoc IRegistry
     */
    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata metadata,
        ResolverUID resolverUID,
        bytes calldata resolverContext
    )
        external
        payable
        returns (address moduleAddress)
    {
        ResolverRecord storage $resolver = $resolvers[resolverUID];
        if ($resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolverUID(resolverUID);

        // prevent someone from calling a registry function pretending its a factory
        if (factory == address(this)) revert FactoryCallFailed(factory);

        // Call the factory via the trampoline contract. This will make sure that there is msg.sender separation
        // Making "raw" calls to user supplied addresses could create security issues.
        moduleAddress = FACTORY_TRAMPOLINE.deployViaFactory{ value: msg.value }({ factory: factory, callOnFactory: callOnFactory });

        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolverUID: resolverUID,
            metadata: metadata
        });

        record.requireExternalResolverOnModuleRegistration({
            moduleAddress: moduleAddress,
            $resolver: $resolver,
            resolverContext: resolverContext
        });
    }

    /**
     * Turns module registration artifacts to `ModuleRecord` to stores it in the registry storage
     * @dev if a non-existent resolverUID is provided, this function reverts.
     * @dev if moduleAddress is already registered, this function reverts.
     * @dev if moduleAddress is not a contract, this function reverts.
     * @param moduleAddress the address of the module to register
     * @param sender the address of the sender who deployed the module
     * @param resolverUID the unique identifier of the resolver
     * @param metadata additional data related to the contract deployment.
     *            This parameter is optional and may be used to facilitate custom business logic on the external resolver
     */
    function _storeModuleRecord(
        address moduleAddress,
        address sender,
        ResolverUID resolverUID,
        bytes calldata metadata
    )
        internal
        returns (ModuleRecord memory moduleRegistration)
    {
        // ensure moduleAddress is not already registered
        if ($moduleAddrToRecords[moduleAddress].resolverUID != EMPTY_RESOLVER_UID) {
            revert AlreadyRegistered(moduleAddress);
        }
        // revert if moduleAddress is NOT a contract
        // this should catch address(0)
        if (!_isContract(moduleAddress)) revert InvalidDeployment();

        // Store module metadata in _modules mapping
        moduleRegistration = ModuleRecord({ resolverUID: resolverUID, sender: sender, metadata: metadata });

        // Store module record in _modules mapping
        $moduleAddrToRecords[moduleAddress] = moduleRegistration;

        // Emit ModuleRegistration event
        emit ModuleRegistration({ implementation: moduleAddress });
    }

    /**
     * @inheritdoc IRegistry
     */
    function findModule(address moduleAddress) external view returns (ModuleRecord memory moduleRecord) {
        return $moduleAddrToRecords[moduleAddress];
    }
}
