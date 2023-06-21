// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { EMPTY_UID, AccessDenied } from "./Common.sol";
import { IRSSchema, SchemaRecord } from "./IRSSchema.sol";

import { ISchemaResolver } from "./resolver/ISchemaResolver.sol";

/**
 * @title The global schema registry.
 */
contract RSSchema is IRSSchema {
    error AlreadyExists();

    // The version of the contract.
    string public constant VERSION = "0.28";

    // The global mapping between schema records and their IDs.
    mapping(bytes32 uid => SchemaRecord schemaRecord) private _schemas;

    /**
     * @inheritdoc IRSSchema
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

        bytes32 uid = _getUID(schemaRecord);
        if (_schemas[uid].uid != EMPTY_UID) {
            revert AlreadyExists();
        }

        schemaRecord.uid = uid;
        _schemas[uid] = schemaRecord;

        emit Registered(uid, msg.sender);

        return uid;
    }

    function setBridges(bytes32 uid, address[] calldata bridges) external onlySchemaOwner(uid) {
        SchemaRecord storage schemaRecord = _schemas[uid];
        schemaRecord.bridges = bridges;
    }

    function setResolver(bytes32 uid, ISchemaResolver resolver) external onlySchemaOwner(uid) {
        SchemaRecord storage schemaRecord = _schemas[uid];
        schemaRecord.resolver = resolver;
        emit NewResolver(uid, address(resolver));
    }

    /**
     * @inheritdoc IRSSchema
     */
    function getSchema(bytes32 uid) public view returns (SchemaRecord memory) {
        return _schemas[uid];
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
            abi.encodePacked(schemaRecord.schema, schemaRecord.resolver, schemaRecord.revocable)
        );
    }

    function _onlySchemaOwner(bytes32 uid) private {
        if (_schemas[uid].schemaOwner != msg.sender) {
            revert AccessDenied();
        }
    }

    function getBridges(bytes32 uid) public view returns (address[] memory) {
        return _schemas[uid].bridges;
    }

    modifier onlySchemaOwner(bytes32 uid) {
        _onlySchemaOwner(uid);
        _;
    }
}
