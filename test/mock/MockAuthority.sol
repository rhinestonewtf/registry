// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../../src/interface/IRSAuthority.sol";
import "../../src/RSRegistry.sol";

/// @title RSAuthoritySample
/// @author zeroknots
/// @notice

contract MockAuthority is IRSAuthority {
    mapping(address contractAddr => RSRegistry.VerificationRecord) public verifications;

    constructor() { }

    function setVerification(
        address contractAddr,
        RSRegistry.VerificationRecord memory record
    )
        external
    {
        verifications[contractAddr] = record;
    }

    function getVerification(
        address contractAddress,
        address smartAccount,
        bytes32 codeHash
    )
        external
        view
        override
        returns (RSRegistry.VerificationRecord memory)
    {
        return verifications[contractAddress];
    }
}
