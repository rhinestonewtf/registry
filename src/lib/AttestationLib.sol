// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AttestationRequest, RevocationRequest, AttestationDataRef } from "../DataTypes.sol";
import { SSTORE2 } from "solady/utils/SSTORE2.sol";

library AttestationLib {
    // The hash of the data type used to relay calls to the attest function. It's the value of
    bytes32 internal constant ATTEST_TYPEHASH =
        keccak256("AttestationRequest(address,uint48,bytes,uint32[])");

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    bytes32 internal constant REVOKE_TYPEHASH = keccak256("RevocationRequest(address)");

    function sload2(AttestationDataRef dataPointer) internal view returns (bytes memory data) {
        data = SSTORE2.read(AttestationDataRef.unwrap(dataPointer));
    }

    function sstore2(
        AttestationRequest calldata request,
        bytes32 salt
    )
        internal
        returns (AttestationDataRef dataPointer)
    {
        /**
         * @dev We are using CREATE2 to deterministically generate the address of the attestation data.
         * Checking if an attestation pointer already exists, would cost more GAS in the average case.
         */
        dataPointer = AttestationDataRef.wrap(SSTORE2.writeDeterministic(request.data, salt));
    }

    function sstore2Salt(address attester, address module) internal view returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(attester, module, block.timestamp, block.chainid));
    }

    function hash(
        AttestationRequest calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        _hash = keccak256(abi.encode(ATTEST_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }

    function hash(
        AttestationRequest[] calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        _hash = keccak256(abi.encode(ATTEST_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }

    function hash(
        RevocationRequest calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        // TODO: check if this is correct
        _hash = keccak256(abi.encode(REVOKE_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }

    function hash(
        RevocationRequest[] calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        // TODO: check if this is correct
        _hash = keccak256(abi.encode(REVOKE_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }
}
