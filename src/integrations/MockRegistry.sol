// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IQuery } from "../interface/IQuery.sol";
import { AttestationRecord } from "../DataTypes.sol";

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
        returns (uint48 listedAt, uint48 revokedAt)
    {
        return (1234, 0);
    }

    function verify(
        address module,
        address[] memory authorities,
        uint256 threshold
    )
        external
        view
        override
    {
        return;
    }

    function verifyUnsafe(
        address module,
        address[] memory authorities,
        uint256 threshold
    )
        external
        view
        override
    {
        return;
    }

    function findAttestation(
        address module,
        address authority
    )
        external
        view
        override
        returns (AttestationRecord memory attestation)
    { }

    function findAttestations(
        address module,
        address[] memory authority
    )
        external
        view
        override
        returns (AttestationRecord[] memory attestations)
    { }
}
