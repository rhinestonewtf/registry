// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { EMPTY_UID, AccessDenied } from "../Common.sol";
import { ISchema, SchemaRecord } from "../interface/ISchema.sol";

import { ISchemaResolver } from "../resolver/ISchemaResolver.sol";

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

    /**
     * @inheritdoc ISchema
     */
    function registerSchema(
        string calldata schema,
        ISchemaResolver resolver,
        bool revocable
    )
        external
        returns (bytes32)
    {
        SchemaRecord memory schemaRecord = SchemaRecord({
            uid: EMPTY_UID,
            schema: schema,
            resolver: resolver,
            revocable: revocable,
            schemaOwner: msg.sender,
            bridges: new address[](0)
        });

        // Computing a unique ID for the schema using its properties
        bytes32 uid = _getUID(schemaRecord);

        // Checking if a schema with this UID already exists
        if (_schemas[uid].uid != EMPTY_UID) {
            revert AlreadyExists();
        }

        // Updating the UID in the schema record and storing it in the _schemas mapping
        schemaRecord.uid = uid;
        _schemas[uid] = schemaRecord;

        emit Registered(uid, msg.sender);

        return uid;
    }

    /**
     * @inheritdoc ISchema
     */
    function setBridges(bytes32 uid, address[] calldata bridges) external onlySchemaOwner(uid) {
        SchemaRecord storage schemaRecord = _schemas[uid];
        schemaRecord.bridges = bridges;
    }

    /**
     * @inheritdoc ISchema
     */
    function setResolver(bytes32 uid, ISchemaResolver resolver) external onlySchemaOwner(uid) {
        SchemaRecord storage schemaRecord = _schemas[uid];
        schemaRecord.resolver = resolver;
        emit NewResolver(uid, address(resolver));
    }

    /**
     * @inheritdoc ISchema
     */
    function getSchema(bytes32 uid) public view virtual returns (SchemaRecord memory) {
        return _schemas[uid];
    }

    /**
     * @inheritdoc ISchema
     */
    function getBridges(bytes32 uid) public view virtual returns (address[] memory) {
        return _schemas[uid].bridges;
    }

    /**
     * @dev Calculates a UID for a given schema.
     *
     * @param schemaRecord The input schema.
     *
     * @return schema UID.
     */
    function _getUID(SchemaRecord memory schemaRecord) private pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(schemaRecord.schema, schemaRecord.schemaOwner, schemaRecord.revocable)
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
        if (_schemas[uid].schemaOwner != msg.sender) {
            revert AccessDenied();
        }
    }
}
