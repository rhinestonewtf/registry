// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    SchemaUID,
    AttestationDataRef,
    AttestationRequest,
    MultiAttestationRequest,
    SignedAttestationRequest,
    MultiSignedAttestationRequest,
    RevocationRequest,
    SignedRevocationRequest,
    MultiSignedRevocationRequest,
    MultiRevocationRequest
} from "../DataTypes.sol";

/**
 * @dev The global attestation interface.
 */
interface IAttestation {
    error AlreadyRevoked();
    error AlreadyRevokedOffchain();
    error AlreadyTimestamped();
    error InsufficientValue();
    error InvalidAttestation();
    error InvalidAttestationRefUID(bytes32 missingRefUID);
    error IncompatibleAttestation(bytes32 sourceCodeHash, bytes32 targetCodeHash);
    error InvalidAttestations();
    error InvalidExpirationTime();
    error InvalidOffset();
    error InvalidRegistry();
    error InvalidRevocation();
    error InvalidRevocations();
    error InvalidVerifier();
    error NotPayable();
    error WrongSchema();
    error InvalidSender(address moduleAddr, address sender);

    /**
     * @dev Emitted when an attestation has been made.
     *
     * @param moduleAddr The moduleAddr of the attestation.
     * @param attester The attesting account.
     * @param schema The UID of the schema.
     */
    event Attested(
        address indexed moduleAddr,
        address indexed attester,
        SchemaUID schema,
        AttestationDataRef indexed dataPointer
    );

    /**
     * @dev Emitted when an attestation has been revoked.
     *
     * @param moduleAddr The moduleAddr of the attestation.
     * @param  revoker The attesting account.
     * @param schema The UID of the schema.
     */
    event Revoked(address indexed moduleAddr, address indexed revoker, SchemaUID indexed schema);

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
     * @notice Creates an attestation for a specified schema.
     *
     * @param request The attestation request.
     */

    function attest(AttestationRequest calldata request) external payable;

    /**
     * @notice Creates multiple attestations for multiple schemas.
     * @dev Although the registry supports batched attestations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     *
     * @param multiRequests An array of multi attestation requests.
     */
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable;

    /**
     * @notice Handles a single signed attestation request
     *
     * @dev The function verifies the attestation,
     *       wraps the data in an array and forwards it to the _multiAttest() function
     *
     * @param signedRequest A signed attestation request
     */
    function attest(SignedAttestationRequest calldata signedRequest) external payable;

    /**
     * @notice Function to handle multiple signed attestation requests
     *
     * @dev It iterates over the attestation requests and processes them. It collects the returned UIDs into a list.
     * @dev Although the registry supports batched attestations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     *
     * @param multiSignedRequests An array of multiple signed attestation requests
     */
    function multiAttest(MultiSignedAttestationRequest[] calldata multiSignedRequests)
        external
        payable;

    /**
     * @notice Revokes an existing attestation for a specified schema.
     *
     * @param request The revocation request.
     */
    function revoke(RevocationRequest calldata request) external payable;
    /**
     * @notice Handles a single signed revocation request
     *
     * @dev The function verifies the revocation, prepares data for the _multiRevoke() function and revokes the requestZ
     *
     * @param request A signed revocation request
     */
    function revoke(SignedRevocationRequest calldata request) external payable;

    /**
     * @notice Handles multiple signed revocation requests
     *
     * @dev The function iterates over the multiSignedRequests array, verifies each revocation and revokes the request
     * @dev Although the registry supports batched revocations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     *
     * @param multiSignedRequests An array of multiple signed revocation requests
     */
    function multiRevoke(MultiSignedRevocationRequest[] calldata multiSignedRequests)
        external
        payable;

    /**
     * @notice Revokes multiple existing attestations for multiple schemas.
     * @dev Although the registry supports batched revocations, the function only allows
     *      batched Attestations for a single resolver.
     *      If you want to attest to multiple resolvers, you need to call the function multiple times.
     * @param multiRequests An array of multi revocation requests.
     */
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable;
}

/**
 * @dev Library for attestation related functions.
 */
library AttestationLib {
    /**
     * @dev Generates a unique salt for an attestation using the provided attester and module addresses.
     * The salt is generated using a keccak256 hash of the module address,
     *     attester address, current timestamp, and chain ID.
     *   This salt will be used for SSTORE2
     *
     * @param attester Address of the entity making the attestation.
     * @param module Address of the module being attested to.
     *
     * @return dataPointerSalt A unique salt for the attestation data storage.
     */
    function attestationSalt(
        address attester,
        address module
    )
        internal
        returns (bytes32 dataPointerSalt)
    {
        dataPointerSalt =
            keccak256(abi.encodePacked(module, attester, block.timestamp, block.chainid));
    }
}
