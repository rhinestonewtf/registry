// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import { StubLib } from "../lib/StubLib.sol";

import { _isContract, EMPTY_RESOLVER_UID, ZERO_ADDRESS } from "../Common.sol";
import { ResolverRecord, ModuleRecord, ResolverUID } from "../DataTypes.sol";
import { ResolverManager } from "./ResolverManager.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * @title Module
 *
 * @dev The Module contract is responsible for handling the registration,
 *           storage and retrieval of modules on the Registry.
 *           This contract inherits from the IModule interface
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

    mapping(address moduleAddress => ModuleRecord moduleRecord) internal $moduleAddrToRecords;

    /**
     * @inheritdoc IRegistry
     */
    function deployModule(
        bytes32 salt,
        ResolverUID resolverUID,
        bytes calldata initCode,
        bytes calldata metadata
    )
        external
        payable
        returns (address moduleAddress)
    {
        ResolverRecord storage $resolver = $resolvers[resolverUID];
        // ensure that existing resolverUID was provided
        if ($resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver($resolver.resolver);

        moduleAddress = initCode.deploy(salt);
        // _storeModuleRecord() will check if module is already registered,
        // which should prevent reentry to any deploy function
        ModuleRecord memory record =
            _storeModuleRecord({ moduleAddress: moduleAddress, sender: msg.sender, resolverUID: resolverUID, metadata: metadata });

        record.requireExternalResolverOnModuleRegistration({ moduleAddress: moduleAddress, $resolver: $resolver });
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
    function registerModule(ResolverUID resolverUID, address moduleAddress, bytes calldata metadata) external {
        ResolverRecord storage $resolver = $resolvers[resolverUID];
        // ensure that existing resolverUID was provided
        if ($resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver($resolver.resolver);

        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolverUID: resolverUID,
            metadata: metadata
        });

        // resolve module registration
        record.requireExternalResolverOnModuleRegistration({ moduleAddress: moduleAddress, $resolver: $resolver });
    }

    /**
     * @inheritdoc IRegistry
     */
    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddress)
    {
        ResolverRecord storage $resolver = $resolvers[resolverUID];
        if ($resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver($resolver.resolver);
        // prevent someone from calling a registry function pretending its a factory
        if (factory == address(this)) revert FactoryCallFailed(factory);
        // call external factory to deploy module
        (bool ok, bytes memory returnData) = factory.call{ value: msg.value }(callOnFactory);
        if (!ok) revert FactoryCallFailed(factory);

        moduleAddress = abi.decode(returnData, (address));
        if (moduleAddress == ZERO_ADDRESS) revert InvalidDeployment();
        if (_isContract(moduleAddress) == false) revert ModuleAddressIsNotContract(moduleAddress);

        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolverUID: resolverUID,
            metadata: metadata
        });

        record.requireExternalResolverOnModuleRegistration({ moduleAddress: moduleAddress, $resolver: $resolver });
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
        emit ModuleRegistration({ implementation: moduleAddress, resolverUID: resolverUID, deployedViaRegistry: sender == msg.sender });
    }

    /**
     * @inheritdoc IRegistry
     */
    function findModule(address moduleAddress) external view returns (ModuleRecord memory moduleRecord) {
        return $moduleAddrToRecords[moduleAddress];
    }
}
