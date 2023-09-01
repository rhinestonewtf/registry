// SPDX-License-Identifier: AGPL-3.0-only
// @author zeroknots
pragma solidity ^0.8.0;

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;

// A zero expiration represents an non-expiring attestation.
uint64 constant NO_EXPIRATION_TIME = 0;

error AccessDenied();
error InvalidSchema();
error InvalidLength();
error InvalidSignature();
error NotFound();

/**
 * @dev A struct representing EIP712 signature data.
 */
struct EIP712Signature {
    uint8 v; // The recovery ID.
    bytes32 r; // The x-coordinate of the nonce R.
    bytes32 s; // The signature data.
}

/**
 * @dev A struct representing a single attestation.
 * inspired by EAS (Ethereum Attestation Service)
 */
struct AttestationRecord {
    bytes32 uid; // A unique identifier of the attestation.
    bytes32 schemaUID; // The unique identifier of the schema.
    bytes32 refUID; // The UID of the related attestation.
    address subject; // The recipient of the attestation i.e. module
    address attester; // The attester/sender of the attestation.
    uint48 time; // The time when the attestation was created (Unix timestamp).
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint48 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    bool revocable; // Whether the attestation is revocable.
    bool propagateable; // Whether the attestation is propagateable to L2s.
    bytes data; // Custom attestation data.
}

// Struct that represents a contract artefact.
struct ModuleRecord {
    address implementation; // The deployed contract address
    bytes32 codeHash; // The hash of the contract code
    bytes32 deployParamsHash; // The hash of the parameters used to deploy the contract
    bytes32 schemaUID; // The id of the schema related to this module
    address deployer; // The address of the sender who deployed the contract
    bytes data; // Additional data related to the contract deployment
}

/**
 * @dev A helper function to work with unchecked iterators in loops.
 */
function uncheckedInc(uint256 i) pure returns (uint256 j) {
    unchecked {
        j = i + 1;
    }
}
