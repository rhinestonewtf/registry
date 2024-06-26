// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { SchemaRecord, SchemaUID } from "../DataTypes.sol";
import { IExternalSchemaValidator } from "../external/IExternalSchemaValidator.sol";
import { UIDLib } from "../lib/Helpers.sol";

import { ZERO_TIMESTAMP, _time } from "../Common.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * Allows the creation registration and creation of schemas.
 *    Schemas are used to describe attestation data. It is recommended to use ABI encoded data as schema.
 *    An external schema validator contract may be provided,
 *    which  will be called for every attestation made against the schema.
 *    arbitrary checks may be implemented, by SchemaValidators
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract SchemaManager is IRegistry {
    using UIDLib for SchemaRecord;

    // The global mapping between schema records and their IDs.
    mapping(SchemaUID uid => SchemaRecord schemaRecord) internal schemas;

    /**
     * If a validator is not address(0), we check if it supports the IExternalSchemaValidator interface
     */
    modifier onlySchemaValidator(IExternalSchemaValidator validator) {
        if (address(validator) != address(0) && !validator.supportsInterface(type(IExternalSchemaValidator).interfaceId)) {
            revert InvalidSchemaValidator(validator);
        }
        _;
    }

    /**
     * @inheritdoc IRegistry
     */
    function registerSchema(
        string calldata schema,
        IExternalSchemaValidator validator
    )
        external
        onlySchemaValidator(validator)
        returns (SchemaUID uid)
    {
        SchemaRecord memory schemaRecord = SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        uid = schemaRecord.getUID();

        // check if schema with this UID already exists.
        // overwriting a schema is not allowed
        if (schemas[uid].registeredAt != ZERO_TIMESTAMP) revert SchemaAlreadyExists(uid);

        // Storing schema in the _schemas mapping
        schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);
    }

    /**
     * @inheritdoc IRegistry
     */
    function findSchema(SchemaUID uid) external view override returns (SchemaRecord memory) {
        return schemas[uid];
    }
}
