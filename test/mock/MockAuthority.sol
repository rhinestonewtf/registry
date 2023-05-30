// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interface/IRSAuthority.sol";
import "../../src/RSRegistry.sol";

/// @title RSAuthoritySample
/// @author zeroknots
/// @notice

contract MockAuthority is IRSAuthority {
    mapping(address contractAddr => RSRegistry.Attestation) public verifications;

    constructor() { }

    function setAttestation(
        address contractAddr,
        RSRegistry.Attestation memory record
    )
        external
    {
        verifications[contractAddr] = record;
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
        return verifications[contractAddress];
    }
}
