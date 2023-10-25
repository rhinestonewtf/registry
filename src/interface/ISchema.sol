// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IResolver } from "../external/IResolver.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";
import { SchemaUID, SchemaRecord, ResolverUID, ResolverRecord } from "../DataTypes.sol";
import { IRegistry } from "./IRegistry.sol";

/**
 * @title The global schema interface.
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
     * @notice Registers a new schema.
     *
     * @dev Ensures that the schema does not already exist and calculates a unique ID for it.
     *
     * @param schema The schema as a string representation.
     * @param validator OPTIONAL Contract address that validates this schema.
     *     If not provided, all attestations made against this schema is assumed to be valid.
     *
     * @return uid The unique ID of the registered schema.
     */
    function registerSchema(
        string calldata schema,
        ISchemaValidator validator
    )
        external
        returns (SchemaUID);

    /**
     * @notice Registers a resolver and associates it with the caller.
     * @dev This function allows the registration of a resolver by computing a unique ID and associating it with the owner.
     *      Emits a SchemaResolverRegistered event upon successful registration.
     *
     * @param _resolver Address of the IResolver to be registered.
     *
     * @return uid The unique ID (ResolverUID) associated with the registered resolver.
     */

    function registerResolver(IResolver _resolver) external returns (ResolverUID);

    /**
     * @notice Updates the resolver for a given UID.
     *
     * @dev Can only be called by the owner of the schema.
     *
     * @param uid The UID of the schema to update.
     * @param resolver The new resolver interface.
     */
    function setResolver(ResolverUID uid, IResolver resolver) external;

    /**
     * @notice Retrieves the schema record for a given UID.
     *
     * @param uid The UID of the schema to retrieve.
     *
     * @return The schema record associated with the given UID.
     */
    function getSchema(SchemaUID uid) external view returns (SchemaRecord memory);

    /**
     * @notice Retrieves the resolver record for a given UID.
     *
     * @param uid The UID of the resolver to retrieve.
     *
     * @return The resolver record associated with the given UID.
     */
    function getResolver(ResolverUID uid) external view returns (ResolverRecord memory);
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

    /**
     * @dev Calculates a UID for a given resolver.
     *
     * @param resolver The input schema.
     *
     * @return ResolverUID.
     */
    function getUID(ResolverRecord memory resolver) internal pure returns (ResolverUID) {
        return ResolverUID.wrap(keccak256(abi.encodePacked(resolver.resolver)));
    }
}
