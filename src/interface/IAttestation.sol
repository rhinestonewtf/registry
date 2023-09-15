// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AttestationRecord, SchemaUID } from "../Common.sol";
// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

// Credits to Ethereum Attestation Service. A lot of these structs are from there.

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

interface IAttestation {
    /**
     * @dev Emitted when an attestation has been made.
     *
     * @param subject The subject of the attestation.
     * @param attester The attesting account.
     * @param schema The UID of the schema.
     */
    event Attested(address indexed subject, address indexed attester, SchemaUID indexed schema);

    /**
     * @dev Emitted when an attestation has been revoked.
     *
     * @param subject The subject of the attestation.
     * @param attester The attesting account.
     * @param schema The UID of the schema.
     */
    event Revoked(address indexed subject, address indexed attester, SchemaUID indexed schema);

    /**
     * @dev Emitted when a data has been timestamped.
     *
     * @param data The data.
     * @param timestamp The timestamp.
     */
    event Timestamped(bytes32 indexed data, uint64 indexed timestamp);

    /**
     * @dev Emitted when a data has been revoked.
     *
     * @param revoker The address of the revoker.
     * @param data The data.
     * @param timestamp The timestamp.
     */
    event RevokedOffchain(address indexed revoker, bytes32 indexed data, uint64 indexed timestamp);

    /**
     * @notice Handles a single delegated attestation request
     *
     * @dev The function verifies the attestation, wraps the data in an array and forwards it to the _attest() function
     *
     * @param delegatedRequest A delegated attestation request
     */
    function attest(DelegatedAttestationRequest calldata delegatedRequest) external payable;

    /**
     * @notice Function to handle multiple delegated attestation requests
     *
     * @dev It iterates over the attestation requests and processes them. It collects the returned UIDs into a list.
     *
     * @param multiDelegatedRequests An array of multiple delegated attestation requests
     */
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable;

    /**
     * @notice Handles a single delegated revocation request
     *
     * @dev The function verifies the revocation, prepares data for the _revoke() function and revokes the requestZ
     *
     * @param request A delegated revocation request
     */
    function revoke(DelegatedRevocationRequest calldata request) external payable;

    /**
     * @notice Handles multiple delegated revocation requests
     *
     * @dev The function iterates over the multiDelegatedRequests array, verifies each revocation and revokes the request
     *
     * @param multiDelegatedRequests An array of multiple delegated revocation requests
     */
    function multiRevoke(MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests)
        external
        payable;

    // /**
    //  * @notice Predicts Attestation UID for a given request
    //  *
    //  * @dev The function returns the UID of the attestation that would be issued for the given request
    //  *
    //  * @param schema The schema of the attestation
    //  * @param attester The attester of the attestation
    //  * @param request The request data
    //  */
    // function predictAttestationUID(
    //     bytes32 schema,
    //     address attester,
    //     AttestationRequestData memory request
    // ) external view returns (bytes32 uid);
}
