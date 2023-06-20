// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interface/IRSAuthority.sol";
import "../../src/RSRegistry.sol";

import "solmate/tokens/ERC20.sol";

/// @title MockTokenizedAuthority
/// @author zeroknots
/// @notice ContractDescription

contract MockTokenizedAuthority is IRSAuthority {
    error InvalidLicense();

    mapping(address contractAddr => RSRegistry.Attestation) public attestations;
    ERC20 public license;

    constructor(address _license) {
        license = ERC20(_license);
    }

    function setAttestation(address contractAddr, RSRegistry.Attestation memory record) external {
        attestations[contractAddr] = record;
    }

    function getAttestation(
        address contractAddress,
        address smartAccount,
        bytes32 codeHash
    )
        external
        view
        override
        returns (RSRegistry.Attestation memory)
    {
        if (license.balanceOf(smartAccount) == 0) revert InvalidLicense();
        return attestations[contractAddress];
    }
}
