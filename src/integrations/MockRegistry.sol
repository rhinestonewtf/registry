// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IQuery } from "../interface/IQuery.sol";
import { AttestationRecord } from "../DataTypes.sol";
import { uncheckedInc } from "../Common.sol";

/// @title MockRegistry
/// @author zeroknots
/// @notice ContractDescription

contract MockRegistry is IQuery {
    function check(
        address plugin,
        address trustedEntity
    )
        external
        view
        override
        returns (uint256 listedAt)
    {
        return uint256(1234);
    }

    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 attestersLength = attesters.length;
        uint256[] memory attestedAtArray = new uint256[](attestersLength);
        for (uint256 i; i < attestersLength; i = uncheckedInc(i)) {
            attestedAtArray[i] = uint256(1234);
        }
        return attestedAtArray;
    }

    function checkNUnsafe(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 attestersLength = attesters.length;
        uint256[] memory attestedAtArray = new uint256[](attestersLength);
        for (uint256 i; i < attestersLength; i = uncheckedInc(i)) {
            attestedAtArray[i] = uint256(1234);
        }
        return attestedAtArray;
    }

    function findAttestation(
        address module,
        address attester
    )
        external
        view
        override
        returns (AttestationRecord memory attestation)
    { }

    function findAttestations(
        address module,
        address[] memory attersters
    )
        external
        view
        override
        returns (AttestationRecord[] memory attestations)
    { }
}
