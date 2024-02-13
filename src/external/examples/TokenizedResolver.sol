// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ResolverBase.sol";
import "forge-std/interfaces/IERC20.sol";

contract TokenizedResolver is ResolverBase {
    IERC20 public immutable TOKEN;
    uint256 internal immutable fee = 1e18;

    constructor(IERC20 _token, IRegistry _registry) ResolverBase(_registry) {
        TOKEN = _token;
    }

    function supportsInterface(bytes4 interfaceID) external view override returns (bool) { }

    function resolveAttestation(AttestationRecord calldata attestation)
        external
        payable
        override
        onlyRegistry
        returns (bool)
    { }

    function resolveAttestation(AttestationRecord[] calldata attestation)
        external
        payable
        override
        onlyRegistry
        returns (bool)
    { }

    function resolveRevocation(AttestationRecord calldata attestation)
        external
        payable
        override
        onlyRegistry
        returns (bool)
    { }

    function resolveRevocation(AttestationRecord[] calldata attestation)
        external
        payable
        override
        onlyRegistry
        returns (bool)
    { }

    function resolveModuleRegistration(
        address sender,
        address moduleAddress,
        ModuleRecord calldata record
    )
        external
        payable
        override
        onlyRegistry
        returns (bool)
    {
        TOKEN.transferFrom(sender, address(this), fee);
    }
}
