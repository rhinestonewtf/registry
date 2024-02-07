// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ISchemaValidator } from "./external/ISchemaValidator.sol";
import { IResolver } from "./external/IResolver.sol";
import { SSTORE2 } from "solady/utils/SSTORE2.sol";

/*//////////////////////////////////////////////////////////////
                          STORAGE 
//////////////////////////////////////////////////////////////*/

// Struct that represents an attestation.
struct AttestationRecord {
    uint48 time; // The time when the attestation was created (Unix timestamp).
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint48 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    PackedModuleTypes moduleTypes; // bit-wise encoded module types. See ModuleTypeLib
    SchemaUID schemaUID; // The unique identifier of the schema.
    address moduleAddr; // The implementation address of the module that is being attested.
    address attester; // The attesting account.
    AttestationDataRef dataPointer; // SSTORE2 pointer to the attestation data.
}

// Struct that represents Module artefact.
struct ModuleRecord {
    ResolverUID resolverUID; // The unique identifier of the resolver.
    address sender; // The address of the sender who deployed the contract
    bytes metadata; // Additional data related to the contract deployment
}

struct SchemaRecord {
    uint48 registeredAt; // The time when the schema was registered (Unix timestamp).
    ISchemaValidator validator; // Optional external schema validator.
    string schema; // Custom specification of the schema (e.g., an ABI).
}

struct ResolverRecord {
    IResolver resolver; // Optional resolver.
    address resolverOwner; // The address of the account used to register the resolver.
}

/*//////////////////////////////////////////////////////////////
                          Attestation Requests
//////////////////////////////////////////////////////////////*/

/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequest {
    address moduleAddr; // The moduleAddr of the attestation.
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    bytes data; // Custom attestation data.
    ModuleType[] moduleTypes; // optional: The type(s) of the module.
}
/*//////////////////////////////////////////////////////////////
                          Revocation Requests
//////////////////////////////////////////////////////////////*/

/**
 * @dev A struct representing the arguments of the revocation request.
 */
struct RevocationRequest {
    address moduleAddr; // The module address.
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

type PackedModuleTypes is uint32;

type ModuleType is uint32;
