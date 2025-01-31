// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IExternalResolver } from "src/external/IExternalResolver.sol";
import "src/DataTypes.sol";

contract RSResolver is IExternalResolver {
    function resolveAttestation(AttestationRecord calldata attestation) public payable returns (bool attestationIsValid) {
        return true;
    }

    function resolveAttestation(AttestationRecord[] calldata attestation) external payable returns (bool) {
        return true;
    }

    function resolveRevocation(AttestationRecord calldata attestation) external payable returns (bool) {
        return true;
    }

    function resolveRevocation(AttestationRecord[] calldata attestation) external payable returns (bool) {
        return true;
    }

    function resolveModuleRegistration(
        address sender,
        address moduleAddress,
        ModuleRecord calldata record,
        bytes calldata resolverContext
    )
        external
        payable
        returns (bool)
    {
        return true;
    }

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return (interfaceID == type(IExternalResolver).interfaceId);
    }
}
