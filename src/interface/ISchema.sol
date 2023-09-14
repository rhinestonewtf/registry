// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

import { ISchemaResolver } from "../resolver/ISchemaResolver.sol";
import { ISchemaValidator } from "../resolver/ISchemaValidator.sol";
import { SchemaUID, ResolverUID } from "../Common.sol";

/**
 * @title A struct representing a record for a submitted schema.
 * Inspired by schema definitions of EAS (Ethereum Attestation Service)
 */
struct SchemaRecord {
    ISchemaValidator validator; // Optional external schema validator.
    uint48 registeredAt;
    string schema; // Custom specification of the schema (e.g., an ABI).
}

struct ResolverRecord {
    ISchemaResolver resolver; // Optional schema resolver.
    address schemaOwner; // The address of the account used to register the schema.
}

/**
 * @title The global schema registry interface.
 */
interface ISchema {
    // Error to throw if the SchemaID already exists
    error AlreadyExists();

    /**
     * @dev Emitted when a new schema has been registered
     *
     * @param uid The schema UID.
     * @param registerer The address of the account used to register the schema.
     */
    event SchemaRegistered(SchemaUID indexed uid, address registerer);

    event SchemaResolverRegistered(ResolverUID indexed uid, address registerer);

    /**
     * @dev Emitted when a new schema resolver
     *
     * @param uid The schema UID.
     * @param resolver The address of the resolver.
     */
    event NewSchemaResolver(ResolverUID indexed uid, address resolver);

    /**
     * @dev Submits and reserves a new schema
     *
     * @param schema The schema data schema.
     * @param resolver An optional schema resolver.
     *
     * @return The UID of the new schema.
     */
    function registerSchema(
        string calldata schema,
        ISchemaValidator resolver
    )
        external
        returns (SchemaUID);

    /**
     * @dev Sets a resolver for a schema
     *
     * @param uid The schema UID.
     * @param resolver The new resolver address.
     */
    function setSchemaResolver(ResolverUID uid, ISchemaResolver resolver) external;

    /**
     * @dev Returns an existing schema by UID
     *
     * @param uid The UID of the schema to retrieve.
     *
     * @return The schema record.
     */
    function getSchema(SchemaUID uid) external view returns (SchemaRecord memory);
}

library SchemaLib {
    /**
     * @dev Calculates a UID for a given schema.
     *
     * @param schemaRecord The input schema.
     *
     * @return schema UID.
     */
    function getUID(SchemaRecord memory schemaRecord) internal pure returns (SchemaUID) {
        return SchemaUID.wrap(
            keccak256(abi.encodePacked(schemaRecord.schema, address(schemaRecord.validator)))
        );
    }

    function getUID(ResolverRecord memory schemaResolver) internal pure returns (ResolverUID) {
        return ResolverUID.wrap(
            keccak256(
                abi.encodePacked(
                    // @zeroknots: this breaks when resolver is changed
                    // I think being able to change the resolver would make a lot of sense
                    schemaResolver.schemaOwner,
                    address(schemaResolver.resolver)
                )
            )
        );
    }
}
