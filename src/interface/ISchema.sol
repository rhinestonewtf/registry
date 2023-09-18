// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.0;

import { IResolver } from "../external/IResolver.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";
import { SchemaUID, SchemaRecord, ResolverUID, ResolverRecord } from "../DataTypes.sol";

import "./IRegistry.sol";
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
    function setResolver(ResolverUID uid, IResolver resolver) external;

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

    function getUID(ResolverRecord memory resolver) internal view returns (ResolverUID) {
        return ResolverUID.wrap(
            keccak256(abi.encodePacked(resolver.resolver, block.timestamp, block.chainid))
        );
    }
}
