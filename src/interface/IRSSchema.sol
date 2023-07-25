// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

import { ISchemaResolver } from "../resolver/ISchemaResolver.sol";

/**
 * @title A struct representing a record for a submitted schema.
 * Inspired by schema definitions of EAS (Ethereum Attestation Service)
 */
struct SchemaRecord {
    bytes32 uid; // The unique identifier of the schema.
    ISchemaResolver resolver; // Optional schema resolver.
    bool revocable; // Whether the schema allows revocations explicitly.
    string schema; // Custom specification of the schema (e.g., an ABI).
    address schemaOwner; // The address of the account used to register the schema.
    address[] bridges; // bridges that must be used for L2 propagation
}

/**
 * @title The global schema registry interface.
 */
interface IRSSchema {
    // Error to throw if the SchemaID already exists
    error AlreadyExists();
    /**
     * @dev Emitted when a new schema has been registered
     *
     * @param uid The schema UID.
     * @param registerer The address of the account used to register the schema.
     */

    event Registered(bytes32 indexed uid, address registerer);

    /**
     * @dev Emitted when a new schema resolver
     *
     * @param uid The schema UID.
     * @param resolver The address of the resolver.
     */
    event NewResolver(bytes32 indexed uid, address resolver);

    /**
     * @dev Submits and reserves a new schema
     *
     * @param schema The schema data schema.
     * @param resolver An optional schema resolver.
     * @param revocable Whether the schema allows revocations explicitly.
     *
     * @return The UID of the new schema.
     */
    function registerSchema(
        string calldata schema,
        ISchemaResolver resolver,
        bool revocable
    )
        external
        returns (bytes32);

    /**
     * @dev Sets the bridges for a schema
     *
     * @param uid The schema UID.
     * @param bridges An array of bridge addresses.
     */
    function setBridges(bytes32 uid, address[] calldata bridges) external;

    /**
     * @dev Returns the bridges for a schema
     *
     * @param uid The schema UID.
     *
     * @return An array of bridge addresses.
     */
    function getBridges(bytes32 uid) external view returns (address[] memory);

    /**
     * @dev Sets a resolver for a schema
     *
     * @param uid The schema UID.
     * @param resolver The new resolver address.
     */
    function setResolver(bytes32 uid, ISchemaResolver resolver) external;

    /**
     * @dev Returns an existing schema by UID
     *
     * @param uid The UID of the schema to retrieve.
     *
     * @return The schema data members.
     */
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
}
