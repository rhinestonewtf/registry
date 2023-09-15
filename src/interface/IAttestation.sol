// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DataTypes.sol";
import { IRegistry } from "./IRegistry.sol";

interface IAttestation {
    error AlreadyRevoked();
    error AlreadyRevokedOffchain();
    error AlreadyTimestamped();
    error InsufficientValue();
    error InvalidAttestation();
    error InvalidAttestationRefUID(bytes32 missingRefUID);
    error IncompatibleAttestation(bytes32 sourceCodeHash, bytes32 targetCodeHash);
    error InvalidPropagation();
    error InvalidAttestations();
    error InvalidExpirationTime();
    error InvalidOffset();
    error InvalidRegistry();
    error InvalidRevocation();
    error InvalidRevocations();
    error InvalidVerifier();
    error NotPayable();
    error WrongSchema();
    error InvalidSender(address moduleAddr, address sender); // Emitted when the sender address is invalid.
    error InvalidCaller(address moduleAddr, address yaruSender); // Emitted when the caller is not the Yaru contract.
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
}
