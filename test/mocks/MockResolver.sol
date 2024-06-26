// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "src/external/IExternalResolver.sol";

contract MockResolver is IExternalResolver {
    bool immutable returnVal;

    bool public onAttestCalled;
    bool public onRevokeCalled;
    bool public onModuleCalled;

    constructor(bool ret) {
        returnVal = ret;
    }

    function reset() public {
        onAttestCalled = false;
        onRevokeCalled = false;
        onModuleCalled = false;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        if (interfaceId == type(IExternalResolver).interfaceId) return true;
    }

    function resolveAttestation(AttestationRecord calldata attestation) external payable override returns (bool) {
        onAttestCalled = true;
        return returnVal;
    }

    function resolveAttestation(AttestationRecord[] calldata attestation) external payable override returns (bool) {
        onAttestCalled = true;
        return returnVal;
    }

    function resolveRevocation(AttestationRecord calldata attestation) external payable override returns (bool) {
        revert();
        onRevokeCalled = true;
        return returnVal;
    }

    function resolveRevocation(AttestationRecord[] calldata attestation) external payable override returns (bool) {
        revert();
        onRevokeCalled = true;
        return returnVal;
    }

    function resolveModuleRegistration(
        address sender,
        address moduleRecord,
        ModuleRecord calldata record,
        bytes calldata resolverContext
    )
        external
        payable
        override
        returns (bool)
    {
        onModuleCalled = true;
        return returnVal;
    }
}
