// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { IAggregator } from "@ERC4337/account-abstraction/contracts/interfaces/IAggregator.sol";
import { PackedUserOperation } from "@ERC4337/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ModuleType } from "../DataTypes.sol";


interface ValidatorSelection {

  function getValidator(PackedUserOperation calldata userOp) external view returns (address validator);

}

abstract contract Aggregator is IAggregator {
    function validateSignatures(PackedUserOperation[] calldata userOps, bytes calldata signature) external view { 
        uint256 length = userOps.length;

        for (uint256 i; i < length; i++) {
            PackedUserOperation calldata userOp = userOps[i];
            address smartAccount = userOp.sender;
            address validator = _getValidator(userOp);
            _check(smartAccount, validator, ModuleType.wrap(1));
        }

    }
    function validateUserOpSignature(PackedUserOperation calldata userOp) external view returns (bytes memory sigForUserOp) { }

    function _getValidator(PackedUserOperation calldata userOp) internal pure returns (address validator) { 
            uint256 nonce = userOp.nonce;
            assembly {
                validator := shr(96, nonce)
            }
            // address validator = ValidatorSelection(smartAccount).getValidator(userOp);
    }



    function aggregateSignatures(PackedUserOperation[] calldata userOps) external view returns (bytes memory aggregatedSignature) {
        uint256 length = userOps.length;

        for (uint256 i; i < length; i++) {
            PackedUserOperation calldata userOp = userOps[i];
            address validator = _getValidator(userOp);
            address smartAccount = userOp.sender;
            _check(smartAccount, validator, ModuleType.wrap(1));

        }
    }

    function _check(address smartAccount, address module, ModuleType moduleType) internal view virtual;
}
