// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SchemaResolver } from "@eas/resolver/SchemaResolver.sol";

import { IEAS, Attestation } from "@eas/IEAS.sol";

import "forge-std/console2.sol";

/// @title SimpleResolver
/// @author zeroknots
/// @notice ContractDescription

contract SimpleResolver is SchemaResolver {
    constructor(IEAS eas) SchemaResolver(eas) { }

    function onAttest(
        Attestation calldata attestation,
        uint256 /*value*/
    )
        internal
        view
        override
        returns (bool)
    {
        console2.log(attestation.attester);

        bytes32 refUID = attestation.refUID;
        if (refUID != "") {
            Attestation memory originalAttestation = _eas.getAttestation(refUID);
            console2.log("original attestation attester: %s", originalAttestation.attester);
        }
        return true;
    }

    function onRevoke(
        Attestation calldata, /*attestation*/
        uint256 /*value*/
    )
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }
}
