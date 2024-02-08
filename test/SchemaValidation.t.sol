// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base.t.sol";

contract SchemaValidationTest is BaseTest {
    modifier whenRegisteringNewSchema() {
        _;
    }

    function test_WhenSchemaAlreadyRegistered() external whenRegisteringNewSchema {
        string memory schema = "schema";
        SchemaUID uid = registry.registerSchema(schema, IExternalSchemaValidator(address(0)));
        SchemaUID uid1 =
            registry.registerSchema(schema, IExternalSchemaValidator(address(schemaValidatorFalse)));

        assertTrue(uid != uid1);
    }

    function test_WhenSchemaNew() external whenRegisteringNewSchema {
        // It should register schema.

        string memory schema = "schema";
        SchemaUID uid = registry.registerSchema(schema, IExternalSchemaValidator(address(0)));

        assertTrue(uid != SchemaUID.wrap(bytes32(0)));
    }
}
