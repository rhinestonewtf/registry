// SPDX-License-Identifier: AGPL-3.0-only
// @author zeroknots
pragma solidity ^0.8.0;

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;

// A zero expiration represents an non-expiring attestation.
uint64 constant NO_EXPIRATION_TIME = 0;

type SchemaUID is bytes32;

using { schemaEq as == } for SchemaUID global;
using { schemaNotEq as != } for SchemaUID global;

function schemaEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) == SchemaUID.unwrap(uid);
}

function schemaNotEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) != SchemaUID.unwrap(uid);
}

type ResolverUID is bytes32;

using { resolverEq as == } for ResolverUID global;
using { resolverNotEq as != } for ResolverUID global;

function resolverEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) == ResolverUID.unwrap(uid2);
}

function resolverNotEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) != ResolverUID.unwrap(uid2);
}

error AccessDenied();
error InvalidSchema();
error InvalidResolver();
error InvalidLength();
error InvalidSignature();
error NotFound();

/**
 * @dev A struct representing EIP712 signature data.
 */
// should consider scraping this entirely and just leave it bytes and use the checkNSignature Lib
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
    SchemaUID schemaUID; // The unique identifier of the schema.
    address subject; // The recipient of the attestation i.e. module
    address attester; // The attester/sender of the attestation.
    uint48 time; // The time when the attestation was created (Unix timestamp).
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint48 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    bytes data; // Custom attestation data.
}

// Struct that represents Module artefact.
struct ModuleRecord {
    ResolverUID resolverUID;
    address implementation; // The deployed contract address
    address sender; // The address of the sender who deployed the contract
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

/**
 * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
 * current block time.
 */
function _time() view returns (uint48) {
    return uint48(block.timestamp);
}
