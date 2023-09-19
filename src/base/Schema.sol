// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { EMPTY_UID, AccessDenied, _time, ZERO_ADDRESS, InvalidResolver } from "../Common.sol";
import { ISchema, SchemaLib } from "../interface/ISchema.sol";

import "../DataTypes.sol";

import { IResolver } from "../external/IResolver.sol";
import { ISchemaValidator } from "../external/ISchemaValidator.sol";
import "forge-std/console2.sol";

/**
 * @title Schema
 *
 * @author zeroknots.eth
 *
 * @dev The Schema contract serves as a crucial component of a broader system for managing "schemas" within a
 * blockchain ecosystem. It provides functionality to register, retrieve and manage schemas. This contract is a
 * concrete implementation of the ISchema interface.
 *
 * @dev The main functionality of the Schema contract includes the registration of new schemas (`registerSchema` function)
 * and the retrieval of existing schemas (`getSchema` function). It also offers additional management features such as
 * setting bridges (`setBridges` function) and resolvers (`setResolver` function) for each schema.
 *
 * @dev Each new schema is registered with a UID that is calculated based on its data members using the `_getUID` function.
 * This UID is used as a key to map the schema record in the `_schemas` mapping. The system ensures uniqueness of the schemas
 * by validating that a schema with the same UID does not already exist.
 *
 * @dev Furthermore, the Schema contract introduces access control by ensuring that certain operations such as setting
 * bridges and resolvers can only be performed by the owner of the schema.
 *
 * @dev In summary, the Schema contract is an integral part of a larger system, providing the functionality to register,
 * retrieve, and manage schemas in a controlled and structured manner.
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
        ISchemaValidator validator
    )
        external
        returns (SchemaUID)
    {
        SchemaRecord memory schemaRecord =
            SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        SchemaUID uid = schemaRecord.getUID();

        if (_schemas[uid].registeredAt != 0) revert AlreadyExists();

        // Storing schema in the _schemas mapping
        _schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);

        return uid;
    }

    /**
     * @inheritdoc ISchema
     */
    function registerResolver(IResolver _resolver) external returns (ResolverUID) {
        if (address(_resolver) == ZERO_ADDRESS) revert InvalidResolver();

        // build a ResolverRecord from the input
        ResolverRecord memory resolver =
            ResolverRecord({ resolver: _resolver, schemaOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        ResolverUID uid = resolver.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address(_resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert AlreadyExists();
        }

        // Storing schema in the _schemas mapping
        _resolvers[uid] = resolver;

        emit SchemaResolverRegistered(uid, msg.sender);

        return uid;
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

    function _getSchema(SchemaUID uid) internal view virtual returns (SchemaRecord storage) {
        return _schemas[uid];
    }

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
