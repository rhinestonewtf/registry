// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

// solhint-disable-next-line max-line-length
bytes constant EXPECTED_SIGNATURE =
    hex"ddeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefeadbeef";

contract ERC1271Attester is IERC1271 {
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;

    function isValidSignature(
        bytes32 hash,
        bytes memory signature
    )
        external
        view
        returns (bytes4 magicValue)
    {
        if (signature.length == EXPECTED_SIGNATURE.length) return MAGICVALUE;
    }
}
