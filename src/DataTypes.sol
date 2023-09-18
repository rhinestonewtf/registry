// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISchemaValidator } from "./external/ISchemaValidator.sol";
import { IResolver } from "./external/IResolver.sol";
/*//////////////////////////////////////////////////////////////
                          STORAGE 
//////////////////////////////////////////////////////////////*/

struct AttestationRecord {
    SchemaUID schemaUID; // The unique identifier of the schema.
    address subject; // The recipient of the attestation i.e. module
    address attester; // The attester/sender of the attestation.
    uint48 time; // The time when the attestation was created (Unix timestamp).
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint48 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    AttestationDataRef dataPointer; // SSTORE2 pointer to the attestation data. (saves gas)
}

// Struct that represents Module artefact.
struct ModuleRecord {
    ResolverUID resolverUID;
    address implementation; // The deployed contract address
    address sender; // The address of the sender who deployed the contract
    bytes data; // Additional data related to the contract deployment
}

struct SchemaRecord {
    ISchemaValidator validator; // Optional external schema validator.
    uint48 registeredAt;
    string schema; // Custom specification of the schema (e.g., an ABI).
}

struct ResolverRecord {
    IResolver resolver; // Optional schema resolver.
    address schemaOwner; // The address of the account used to register the schema.
}

/*//////////////////////////////////////////////////////////////
                          Attestation Requests
//////////////////////////////////////////////////////////////*/
/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequestData {
    address subject; // The subject of the attestation.
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
    bytes data; // Custom attestation data.
}

/**
 * @dev A struct representing the full arguments of the attestation request.
 */
struct AttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
struct DelegatedAttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    bytes signature; // The signature data.
    address attester; // The attesting account.
}

/**
 * @dev A struct representing the full arguments of the multi attestation request.
 */
struct MultiAttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi attestation request.
 */
struct MultiDelegatedAttestationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation requests.
    bytes[] signatures; // The signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address attester; // The attesting account.
}
/*//////////////////////////////////////////////////////////////
                          Revocation Requests
//////////////////////////////////////////////////////////////*/

/**
 * @dev A struct representing the arguments of the revocation request.
 */
struct RevocationRequestData {
    address subject; // The UID of the attestation to revoke.
    address attester;
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the revocation request.
 */
struct RevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the arguments of the full delegated revocation request.
 */
struct DelegatedRevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
    bytes signature; // The signature data.
    address revoker; // The revoking account.
}

/**
 * @dev A struct representing the full arguments of the multi revocation request.
 */
struct MultiRevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi revocation request.
 */
struct MultiDelegatedRevocationRequest {
    SchemaUID schemaUID; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation requests.
    bytes[] signatures; // The signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address revoker; // The revoking account.
}

/*//////////////////////////////////////////////////////////////
                          CUSTOM TYPES
//////////////////////////////////////////////////////////////*/

//---------------------- SchemaUID ------------------------------|
type SchemaUID is bytes32;

using { schemaEq as == } for SchemaUID global;
using { schemaNotEq as != } for SchemaUID global;

function schemaEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) == SchemaUID.unwrap(uid);
}

function schemaNotEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) != SchemaUID.unwrap(uid);
}

//--------------------- ResolverUID -----------------------------|
type ResolverUID is bytes32;

using { resolverEq as == } for ResolverUID global;
using { resolverNotEq as != } for ResolverUID global;

function resolverEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) == ResolverUID.unwrap(uid2);
}

function resolverNotEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) != ResolverUID.unwrap(uid2);
}

type AttestationDataRef is address;

import { SSTORE2 } from "solady/src/utils/SSTORE2.sol";

function readAttestationData(AttestationDataRef dataPointer) view returns (bytes memory data) {
    data = SSTORE2.read(AttestationDataRef.unwrap(dataPointer));
}

function writeAttestationData(
    bytes memory attestationData,
    bytes32 salt
)
    returns (AttestationDataRef dataPointer)
{
    dataPointer = AttestationDataRef.wrap(SSTORE2.writeDeterministic(attestationData, salt));
}
