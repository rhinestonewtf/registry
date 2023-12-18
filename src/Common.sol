// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;

// A zero expiration represents an non-expiring attestation.
uint256 constant ZERO_TIMESTAMP = 0;

address constant ZERO_ADDRESS = address(0);

error AccessDenied();
error InvalidSchema();
error InvalidResolver();
error InvalidLength();
error InvalidSignature();
error NotFound();

/**
 * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
 * current block time.
 */
function _time() view returns (uint48) {
    return uint48(block.timestamp);
}

/**
 * @dev Returns whether an address is a contract.
 * @param account The address to check.
 *
 * @return true if `account` is a contract, false otherwise.
 */
function _isContract(address account) view returns (bool) {
    uint256 size;
    assembly {
        size := extcodesize(account)
    }
    return size > 0;
}
