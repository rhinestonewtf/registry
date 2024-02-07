// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { SchemaRecord, ResolverRecord, SchemaUID, ResolverUID } from "../DataTypes.sol";
import { IExternalSchemaValidator } from "../external/IExternalSchemaValidator.sol";
import { UIDLib } from "../lib/Helpers.sol";

import { ZERO_TIMESTAMP, _time } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

abstract contract SchemaManager is IRegistry {
    using UIDLib for SchemaRecord;
    // The global mapping between schema records and their IDs.

    mapping(SchemaUID uid => SchemaRecord schemaRecord) internal schemas;

    function registerSchema(
        string calldata schema,
        IExternalSchemaValidator validator // OPTIONAL
    )
        external
        returns (SchemaUID uid)
    {
        // TODO: ERC165 check that validator is actually a valivator
        SchemaRecord memory schemaRecord =
            SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        uid = schemaRecord.getUID();

        if (schemas[uid].registeredAt != ZERO_TIMESTAMP) revert AlreadyExists();

        // Storing schema in the _schemas mapping
        schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);
    }
}
