// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IQuery } from "../../interface/IQuery.sol";

bytes32 constant REGISTRY_INTEGRATION_SLOT = keccak256("RegistryIntegration.storage.location");

library RegistryIntegrationStorage {
    struct Storage {
        IQuery registry;
        address trustedAttester;
    }

    function store() internal pure returns (Storage storage s) {
        bytes32 slot = REGISTRY_INTEGRATION_SLOT;
        assembly {
            s.slot := slot
        }
    }
}

/**
 * @title RegistryIntegrationStorageSlot
 * @author zeroknots
 *
 * @dev This contract allows only trusted contracts (attested by a specific attester)
 * to interact with it by leveraging the IQuery registry
 */
abstract contract RegistryIntegrationStorageSlot {
    error TargetContractNotPermitted(address target, uint48 listedAt, uint48 flaggedAt);

    /**
     * @dev Constructs the contract and initializes the registry and the trusted attester
     *
     * @param _registry The address of the IQuery registry
     * @param _trustedAttester The address of the trusted attester
     */
    function _set(address _registry, address _trustedAttester) internal {
        RegistryIntegrationStorage.Storage storage s = RegistryIntegrationStorage.store();
        s.registry = IQuery(_registry);
        s.trustedAttester = _trustedAttester;
    }

    /**
     * @notice Internal function that checks the registry for a contract's status
     *
     * @dev Queries the registry with the provided contract address and the trusted attester
     *
     * @param _contract The address of the contract to be checked in the registry
     * @return listedAt The timestamp at which the contract was listed (0 if never listed)
     */

    function _checkRegistry(address _contract) internal view returns (uint48 listedAt) {
        RegistryIntegrationStorage.Storage storage s = RegistryIntegrationStorage.store();
        return s.registry.check(_contract, s.trustedAttester);
    }

    /**
     * @dev Modifier that allows only allowed contracts to interact
     *
     * @notice If the contract has ever been flagged or was never attested to, the interaction will be reverted
     *
     * @param _contract The address of the contract to be checked
     */
    modifier onlyWithRegistryCheck(address _contract) {
        uint48 listedAt = _checkRegistry(_contract);

        // revert if contract was ever flagged or was never attested to
        if (listedAt == 0) {
            revert TargetContractNotPermitted(_contract, listedAt, 0);
        }
        _;
    }
}
