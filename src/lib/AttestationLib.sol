// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { EIP712 } from "solady/utils/EIP712.sol";
import { AttestationRequestData } from "../DataTypes.sol";

// The hash of the data type used to relay calls to the attest function. It's the value of
bytes32 constant ATTEST_TYPEHASH = keccak256("AttestationRequestData(address,uint48,uint256,bytes)");

// The hash of the data type used to relay calls to the revoke function. It's the value of
bytes32 constant REVOKE_TYPEHASH = keccak256("RevocationRequestData(address,address,uint256)");

library AttestationLib {
    function digest(
        AttestationRequestData calldata data,
        uint256 nonce
    )
        internal
        returns (bytes32 digest)
    {
        digest = _hashTypedData(
            keccak256(
                abi.encodePacked(
                    ATTEST_TYPEHASH,
                    block.chainid,
                    data.requester,
                    data.timestamp,
                    data.expiration,
                    data.schema,
                    nonce
                )
            )
        );
    }
}
