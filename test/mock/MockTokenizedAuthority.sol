// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MockAuthority.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockTokenizedAuthority
/// @author zeroknots
/// @notice ContractDescription

contract MockTokenizedAuthority is MockAuthority {
    ERC20 public license;

    constructor(address _license) {
        license = ERC20(_license);
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
        require(license.balanceOf(smartAccount) > 0, "License Invalid");
        return attestations[contractAddress];
    }
}
