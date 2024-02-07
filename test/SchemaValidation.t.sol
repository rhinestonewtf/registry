// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SchemaValidationTest {
    modifier whenRegisteringNewSchema() {
        _;
    }

    function test_WhenSchemaAlreadyRegistered() external whenRegisteringNewSchema {
        // It should revert.
    }

    function test_WhenSchemaNew() external whenRegisteringNewSchema {
        // It should register schema.
        // It should emit event.
    }
}
