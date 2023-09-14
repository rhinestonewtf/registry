// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { EMPTY_UID, AccessDenied, _time, InvalidResolver } from "../Common.sol";
import { ISchema, SchemaRecord, SchemaResolver } from "../interface/ISchema.sol";

import { ISchemaResolver } from "../resolver/ISchemaResolver.sol";
import { ISchemaValidator } from "../resolver/ISchemaValidator.sol";

/**
 * @title Schema
 *
 * @author zeroknots.eth
 *
 * @dev The Schema contract serves as a crucial component of a broader system for managing "schemas" within a
 * blockchain ecosystem. It provides functionality to register, retrieve and manage schemas. This contract is a
 * concrete implementation of the ISchema interface.
 *
 * @dev A schema in this context is a defined structure that represents a record for a submitted schema,
 * encompassing its unique identifier (UID), resolver (optional), revocability status, specification, owner's address,
 * and associated bridges for Layer 2 (L2) propagation.
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
    // The version of the contract.
    string public constant VERSION = "0.1";

    // The global mapping between schema records and their IDs.
    mapping(bytes32 uid => SchemaRecord schemaRecord) private _schemas;

    mapping(bytes32 uid => SchemaResolver resolver) private _resolvers;

    /**
     * @inheritdoc ISchema
     */
    function registerSchema(
        string calldata schema,
        ISchemaValidator validator
    )
        external
        returns (bytes32)
    {
        SchemaRecord memory schemaRecord =
            SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        bytes32 uid = _getUID(schemaRecord);

        // @TODO: better way to make this check?
        // Checking if a schema with this UID already exists
        // very gas intensive.
        // I think it would be better to spend a bit more gas on schema creation and make it cheaper
        // during usage. Maybe we can add a timestamp when it was created or so?
        if (bytes(_schemas[uid].schema).length != 0) {
            revert AlreadyExists();
        }

        // Storing schema in the _schemas mapping
        _schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);

        // @TODO: remove this
        return uid;
    }

    function registerSchemaResolver(ISchemaResolver resolver) external returns (bytes32) {
        if (address(resolver) == address(0)) revert InvalidResolver();
        SchemaResolver memory referrer =
            SchemaResolver({ resolver: resolver, schemaOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        bytes32 uid = _getUID(referrer);

        // Checking if a schema with this UID already exists -> owner can never be address(0)
        if (_resolvers[uid].schemaOwner != address(0)) {
            revert AlreadyExists();
        }

        // Storing schema in the _schemas mapping
        _resolvers[uid] = referrer;

        emit SchemaResolverRegistered(uid, msg.sender);

        return uid;
    }

    function setSchemaResolver(
        bytes32 uid,
        ISchemaResolver resolver
    )
        external
        onlySchemaOwner(uid)
    {
        SchemaResolver storage referrer = _resolvers[uid];
        referrer.resolver = resolver;
        emit NewSchemaResolver(uid, address(resolver));
    }

    /**
     * @inheritdoc ISchema
     */
    function getSchema(bytes32 uid) public view virtual returns (SchemaRecord memory) {
        return _schemas[uid];
    }

    function getSchemaResolver(bytes32 uid) public view virtual returns (SchemaResolver memory) {
        return _resolvers[uid];
    }

    /**
     * @dev Calculates a UID for a given schema.
     *
     * @param schemaRecord The input schema.
     *
     * @return schema UID.
     */
    function _getUID(SchemaRecord memory schemaRecord) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(schemaRecord.schema, address(schemaRecord.validator)));
    }

    function _getUID(SchemaResolver memory referrer) private pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                // @zeroknots: this breaks when resolver is changed
                // I think being able to change the resolver would make a lot of sense
                referrer.schemaOwner,
                address(referrer.resolver)
            )
        );
    }

    /**
     * @dev Modifier to require that the caller is the owner of a schema
     *
     * @param uid The UID of the schema.
     */
    modifier onlySchemaOwner(bytes32 uid) {
        _onlySchemaOwner(uid);
        _;
    }

    /**
     * @dev Verifies that the caller is the owner of a schema
     *
     * @param uid The UID of the schema.
     */
    function _onlySchemaOwner(bytes32 uid) private view {
        if (_resolvers[uid].schemaOwner != msg.sender) {
            revert AccessDenied();
        }
    }
}
