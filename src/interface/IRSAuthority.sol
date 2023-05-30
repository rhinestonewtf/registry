// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import { RSRegistry } from "../RSRegistry.sol";

interface IRSAuthority {
    function getAttestation(
        address contractAddr,
        address smartAccount,
        bytes32 codeHash
    )
        external
        view
        returns (RSRegistry.Attestation memory);
}
