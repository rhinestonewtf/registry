// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IQuery } from "../../interface/IQuery.sol";

/**
 * @title SimpleRegistryIntegration
 * @author zeroknots
 *
 * @dev This contract allows only trusted contracts (attested by a specific attester)
 * to interact with it by leveraging the IQuery registry
 */
abstract contract RegistryIntegration {
    IQuery public immutable registry; // Instance of the registry
    address[] public trustedAttesters; // Address of the trusted attesters
    uint256 public immutable threshold; // Number of attestations required for verification

    error TargetContractNotPermitted(address target);

    /**
     * @dev Constructs the contract and initializes the registry and the trusted attester
     *
     * @param _registry The address of the IQuery registry
     * @param _trustedAttester The address of the trusted attester
     */
    constructor(address _registry, address[] memory _trustedAttester, uint256 _threshold) {
        registry = IQuery(_registry);
        trustedAttesters = _trustedAttester;
        threshold = _threshold;
    }

    /**
     * @notice Internal function that checks the registry for a contract's status
     *
     * @dev Queries the registry with the provided contract address and the trusted attester
     *
     * @param _contract The address of the contract to be checked in the registry
     * @return validCheck the registry returned a boolean if the attestations with selected threshold was valid
     */

    function _checkRegistry(address _contract) internal view returns (bool validCheck) {
        registry.verify(_contract, trustedAttesters, threshold);
        return true;
    }

    /**
     * @dev Modifier that allows only allowed contracts to interact
     *
     * @notice If the contract has ever been flagged or was never attested to, the interaction will be reverted
     *
     * @param _contract The address of the contract to be checked
     */
    modifier onlyWithRegistryCheck(address _contract) {
        bool valid = _checkRegistry(_contract);

        // revert if contract was ever flagged or was never attested to
        if (!valid) {
            revert TargetContractNotPermitted(_contract);
        }
        _;
    }
}
