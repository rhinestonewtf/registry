// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

contract MockFactory {
    function deploy(bytes memory bytecode) external returns (address addr) {
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
}
