// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ResolverRecord, ResolverUID } from "../DataTypes.sol";

abstract contract SchemaManager {
    // The global mapping between schema records and their IDs.
    mapping(SchemaUID uid => SchemaRecord schemaRecord) internal schemas;

    function registerSchema(
        string calldata schema,
        ISchemaValidator validator // OPTIONAL
    )
        external
        returns (SchemaUID uid)
    {
        // TODO: ERC165 check that validator is actually a valivator
        SchemaRecord memory schemaRecord =
            SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        uid = schemaRecord.getUID();

        if (_schemas[uid].registeredAt != ZERO_TIMESTAMP) revert AlreadyExists();

        // Storing schema in the _schemas mapping
        _schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);
    }
}
