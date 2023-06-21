// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Attestation, EIP712Signature } from "./Common.sol";
// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequestData {
    address recipient; // The recipient of the attestation.
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    bool revocable; // Whether the attestation is revocable.
    bool propagateable; // Whether the attestation is propagateable to L2s.
    bytes32 refUID; // The UID of the related attestation.
    bytes data; // Custom attestation data.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the attestation request.
 */
struct AttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
struct DelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    EIP712Signature signature; // The EIP712 signature data.
    address attester; // The attesting account.
}

/**
 * @dev A struct representing the full arguments of the multi attestation request.
 */
struct MultiAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi attestation request.
 */
struct MultiDelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData[] data; // The arguments of the attestation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address attester; // The attesting account.
}

/**
 * @dev A struct representing the arguments of the revocation request.
 */
struct RevocationRequestData {
    bytes32 uid; // The UID of the attestation to revoke.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}

/**
 * @dev A struct representing the full arguments of the revocation request.
 */
struct RevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the arguments of the full delegated revocation request.
 */
struct DelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData data; // The arguments of the revocation request.
    EIP712Signature signature; // The EIP712 signature data.
    address revoker; // The revoking account.
}

/**
 * @dev A struct representing the full arguments of the multi revocation request.
 */
struct MultiRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation request.
}

/**
 * @dev A struct representing the full arguments of the delegated multi revocation request.
 */
struct MultiDelegatedRevocationRequest {
    bytes32 schema; // The unique identifier of the schema.
    RevocationRequestData[] data; // The arguments of the revocation requests.
    EIP712Signature[] signatures; // The EIP712 signatures data. Please note that the signatures are assumed to be signed with increasing nonces.
    address revoker; // The revoking account.
}

interface IRSAttestation {
    /**
     * @dev Emitted when an attestation has been made.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param uid The UID the revoked attestation.
     * @param schema The UID of the schema.
     */
    event Attested(
        address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schema
    );

    /**
     * @dev Emitted when an attestation has been revoked.
     *
     * @param recipient The recipient of the attestation.
     * @param attester The attesting account.
     * @param schema The UID of the schema.
     * @param uid The UID the revoked attestation.
     */
    event Revoked(
        address indexed recipient, address indexed attester, bytes32 uid, bytes32 indexed schema
    );

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
     * @return attestationId The ID of the performed attestation
     */
    function attest(DelegatedAttestationRequest calldata delegatedRequest)
        external
        payable
        returns (bytes32 attestationId);

    /**
     * @notice Function to handle multiple delegated attestation requests
     *
     * @dev It iterates over the attestation requests and processes them. It collects the returned UIDs into a single list.
     *
     * @param multiDelegatedRequests An array of multiple delegated attestation requests
     * @return attestationIds An array of IDs of the performed attestations
     */
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable
        returns (bytes32[] memory attestationIds);

    /**
     * @notice Propagates the attestations to a different blockchain.
     *
     * @dev Encodes the attestation record and sends it as a message to the destination chain.
     *
     * @param to The address to send to on the destination chain
     * @param toChainId The ID of the destination chain
     * @param attestationId The ID of the attestation to be propagated
     * @param moduleOnL2 The address of the module on the Layer 2 chain
     * @param destinationAdapters The destination adapters to send the messages
     * @return messages An array of messages sent
     * @return messageIds An array of IDs of the messages sent
     */
    function propagateAttest(
        address to,
        uint256 toChainId,
        bytes32 attestationId,
        address moduleOnL2,
        address[] calldata destinationAdapters
    )
        external
        returns (Message[] memory messages, bytes32[] memory messageIds);

    /**
     * @notice Handles the attestation by propagation method
     *
     * @dev The function verifies the code hash and stores the attestation. Only accessible by Hashi
     *
     * @param attestation The attestation data
     * @param codeHash The hash of the code
     * @param moduleAddress The address of the module
     */
    function attestByPropagation(
        Attestation calldata attestation,
        bytes32 codeHash,
        address moduleAddress
    )
        external;
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
}
