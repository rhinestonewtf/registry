// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/**
 * @title ModuleDeploymentLib
 * @dev A library that can be used to deploy the Registry
 * @author zeroknots
 */
library ModuleDeploymentLib {
    /**
     * @notice Creates a new contract using CREATE2 opcode.
     * @dev This method uses the CREATE2 opcode to deploy a new contract with a deterministic address.
     *
     * @param initCode The creationCode for the contract.
     *               this MUST be provided. Function will fail if params are abi.encodePacked in createCode.
     *
     * @return moduleAddress The address of the deployed contract.
     */
    function deploy(bytes memory initCode, bytes32 salt) internal returns (address moduleAddress) {
        uint256 value = msg.value;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            moduleAddress := create2(value, add(initCode, 0x20), mload(initCode), salt)
            // If the contract was not created successfully, the transaction is reverted.
            if iszero(extcodesize(moduleAddress)) { revert(0, 0) }
        }
    }

    /**
     * @notice Calculates the deterministic address of a contract that would be deployed using the CREATE2 opcode.
     * @dev The calculated address is based on the contract's code, a salt, and the address of the current contract.
     * @dev This function uses the formula specified in EIP-1014 (https://eips.ethereum.org/EIPS/eip-1014).
     *
     * @param _code The contract code that would be deployed.
     * @param _salt A salt used for the address calculation.
     *                 This must be the same salt that would be passed to the CREATE2 opcode.
     *
     * @return The address that the contract would be deployed
     *            at if the CREATE2 opcode was called with the specified _code and _salt.
     */
    function calcAddress(bytes calldata _code, bytes32 _salt) internal view returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_code)));
        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    error InvalidDeployment();
}
