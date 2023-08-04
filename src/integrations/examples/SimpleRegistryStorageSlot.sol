// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IRSQuery } from "../../interface/IRSQuery.sol";

bytes32 constant REGISTRY_INTEGRATION_SLOT =
    keccak256("RhinestoneRegistryIntegration.storage.location");

library RegistryIntegrationStorage {
    struct Storage {
        IRSQuery registry;
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
 * to interact with it by leveraging the IRSQuery registry
 */
abstract contract RegistryIntegrationStorageSlot {
    error TargetContractNotPermitted(address target, uint48 listedAt, uint48 flaggedAt);

    /**
     * @dev Constructs the contract and initializes the registry and the trusted attester
     *
     * @param _registry The address of the IRSQuery registry
     * @param _trustedAttester The address of the trusted attester
     */
    function _set(address _registry, address _trustedAttester) internal {
        RegistryIntegrationStorage.Storage storage s = RegistryIntegrationStorage.store();
        s.registry = IRSQuery(_registry);
        s.trustedAttester = _trustedAttester;
    }
    /**
     * @notice Internal function that checks the registry for a contract's status
     *
     * @dev Queries the registry with the provided contract address and the trusted attester
     *
     * @param _contract The address of the contract to be checked in the registry
     * @return listedAt The timestamp at which the contract was listed (0 if never listed)
     * @return revokedAt The timestamp at which the contract was revoked (0 if never revoked)
     */

    function _checkRegistry(address _contract)
        internal
        view
        returns (uint48 listedAt, uint48 revokedAt)
    {
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
        (uint48 listedAt, uint48 revokedAt) = _checkRegistry(_contract);

        // revert if contract was ever flagged or was never attested to
        if (listedAt == 0 || revokedAt != 0) {
            revert TargetContractNotPermitted(_contract, listedAt, revokedAt);
        }
        _;
    }
}
