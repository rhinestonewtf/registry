// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { AccessDenied, _time, ZERO_ADDRESS, InvalidResolver } from "../Common.sol";
import { ISchema, SchemaLib } from "../interface/ISchema.sol";
import { IResolver } from "../external/IResolver.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";

import { SchemaRecord, ResolverRecord, SchemaUID, ResolverUID } from "../DataTypes.sol";

/**
 * @title Schema
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 *
 */
abstract contract Schema is ISchema {
    using SchemaLib for SchemaRecord;
    using SchemaLib for ResolverRecord;

    // The global mapping between schema records and their IDs.
    mapping(SchemaUID uid => SchemaRecord schemaRecord) private _schemas;

    mapping(ResolverUID uid => ResolverRecord resolverRecord) private _resolvers;

    /**
     * @inheritdoc ISchema
     */
    function registerSchema(
        string calldata schema,
        ISchemaValidator validator // OPTIONAL
    )
        external
        returns (SchemaUID uid)
    {
        SchemaRecord memory schemaRecord =
            SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        uid = schemaRecord.getUID();

        if (_schemas[uid].registeredAt != 0) revert AlreadyExists();

        // Storing schema in the _schemas mapping
        _schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);
    }

    /**
     * @inheritdoc ISchema
     */
    function registerResolver(IResolver _resolver) external returns (ResolverUID uid) {
        if (address(_resolver) == ZERO_ADDRESS) revert InvalidResolver();

        // build a ResolverRecord from the input
        ResolverRecord memory resolver =
            ResolverRecord({ resolver: _resolver, schemaOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        uid = resolver.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address(_resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert AlreadyExists();
        }

        // Storing schema in the _schemas mapping
        _resolvers[uid] = resolver;

        emit SchemaResolverRegistered(uid, msg.sender);
    }

    /**
     * @inheritdoc ISchema
     */
    function setResolver(ResolverUID uid, IResolver resolver) external onlySchemaOwner(uid) {
        ResolverRecord storage referrer = _resolvers[uid];
        referrer.resolver = resolver;
        emit NewSchemaResolver(uid, address(resolver));
    }

    /**
     * @inheritdoc ISchema
     */
    function getSchema(SchemaUID uid) public view virtual returns (SchemaRecord memory) {
        return _schemas[uid];
    }

    /**
     * @dev Internal function to get a schema record
     *
     * @param uid The UID of the schema.
     *
     * @return schemaRecord The schema record.
     */
    function _getSchema(SchemaUID uid) internal view virtual returns (SchemaRecord storage) {
        return _schemas[uid];
    }

    /**
     * @inheritdoc ISchema
     */
    function getResolver(ResolverUID uid) public view virtual returns (ResolverRecord memory) {
        return _resolvers[uid];
    }

    /**
     * @dev Modifier to require that the caller is the owner of a schema
     *
     * @param uid The UID of the schema.
     */
    modifier onlySchemaOwner(ResolverUID uid) {
        _onlySchemaOwner(uid);
        _;
    }

    /**
     * @dev Verifies that the caller is the owner of a schema
     *
     * @param uid The UID of the schema.
     */
    function _onlySchemaOwner(ResolverUID uid) private view {
        if (_resolvers[uid].schemaOwner != msg.sender) {
            revert AccessDenied();
        }
    }
}
