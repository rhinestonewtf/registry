// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/**
 * @title ModuleDeploymentLib
 * @dev A library that can be used to deploy the Registry
 * @author zeroknots
 */
library ModuleDeploymentLib {
    error InvalidSalt();
    error InvalidAddress();
    // source: https://github.com/0age/metamorphic/blob/master/contracts/ImmutableCreate2Factory.sol#L194-L203

    modifier containsCaller(bytes32 salt) {
        // prevent contract submissions from being stolen from tx.pool by requiring
        // that the first 20 bytes of the submitted salt match msg.sender.
        if ((address(bytes20(salt)) != msg.sender) && (bytes20(salt) != bytes20(0))) revert InvalidSalt();
        _;
    }

    function deploy(bytes calldata _initCode, bytes32 salt) internal containsCaller(salt) returns (address deploymentAddress) {
        // move the initialization code from calldata to memory.
        bytes memory initCode = _initCode;

        // determine the target address for contract deployment.
        address targetDeploymentAddress = calcAddress(_initCode, salt);

        // using inline assembly: load data and length of data, then call CREATE2.
        assembly {
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load the init code's length.
            deploymentAddress :=
                create2( // call CREATE2 with 4 arguments.
                    callvalue(), // forward any attached value.
                    encoded_data, // pass in initialization code.
                    encoded_size, // pass in init code's length.
                    salt // pass in the salt value.
                )
        }

        // check address against target to ensure that deployment was successful.
        if (deploymentAddress != targetDeploymentAddress) revert InvalidAddress();
    }

    /**
     * @notice Calculates the deterministic address of a contract that would be deployed using the CREATE2 opcode.
     * @dev The calculated address is based on the contract's code, a salt, and the address of the current contract.
     * @dev This function uses the formula specified in EIP-1014 (https://eips.ethereum.org/EIPS/eip-1014).
     *
     * @param initCode The contract code that would be deployed.
     * @param salt A salt used for the address calculation.
     *                 This must be the same salt that would be passed to the CREATE2 opcode.
     *
     * @return targetDeploymentAddress The address that the contract would be deployed
     *            at if the CREATE2 opcode was called with the specified _code and _salt.
     */
    function calcAddress(bytes calldata initCode, bytes32 salt) internal view returns (address targetDeploymentAddress) {
        targetDeploymentAddress = address(
            uint160( // downcast to match the address type.
                uint256( // convert to uint to truncate upper digits.
                    keccak256( // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            hex"ff", // start with 0xff to distinguish from RLP.
                            address(this), // this contract will be the caller.
                            salt, // pass in the supplied salt value.
                            keccak256( // pass in the hash of initialization code.
                            abi.encodePacked(initCode))
                        )
                    )
                )
            )
        );
    }

    error InvalidDeployment();
}
