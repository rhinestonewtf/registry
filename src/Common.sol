// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { ResolverUID, SchemaUID, AttestationDataRef, ModuleType } from "./DataTypes.sol";

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;
ResolverUID constant EMPTY_RESOLVER_UID = ResolverUID.wrap(EMPTY_UID);
SchemaUID constant EMPTY_SCHEMA_UID = SchemaUID.wrap(EMPTY_UID);

// A zero expiration represents an non-expiring attestation.
uint256 constant ZERO_TIMESTAMP = 0;

address constant ZERO_ADDRESS = address(0);
ModuleType constant ZERO_MODULE_TYPE = ModuleType.wrap(0);

AttestationDataRef constant EMPTY_ATTESTATION_REF = AttestationDataRef.wrap(address(0));

/**
 * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
 * current block time.
 */
function _time() view returns (uint48) {
    return uint48(block.timestamp);
}

/**
 * @dev Returns whether an address is a contract.
 * @param addr The address to check.
 *
 * @return true if `account` is a contract, false otherwise.
 */
function _isContract(address addr) view returns (bool) {
    return addr.code.length > 0;
}
