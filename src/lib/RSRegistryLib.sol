// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;
// A library that provides functions related to registry operations.

library RSRegistryLib {
    // Gets the code hash of a contract at a given address.
    // @param contractAddr The address of the contract.
    // @return codeHash The hash of the contract code.
    function codeHash(address contractAddr) internal view returns (bytes32 hash) {
        assembly {
            if iszero(extcodesize(contractAddr)) { revert(0, 0) }
            hash := extcodehash(contractAddr)
        }
    }

    /// @notice Creates a new contract using CREATE2 opcode.
    /// @dev This method uses the CREATE2 opcode to deploy a new contract with a deterministic address.
    /// @param createCode The creationCode for the contract.
    /// @param params The parameters for creating the contract. If the contract has a constructor, this MUST be provided. Function will fail if params are abi.encodePacked in createCode.
    /// @param salt The salt for creating the contract.
    /// @return moduleAddress The address of the deployed contract.
    /// @return initCodeHash packed (creationCode, constructor params)
    /// @return contractCodeHash hash of deployed bytecode
    function deploy(
        bytes memory createCode,
        bytes memory params,
        uint256 salt
    )
        internal
        returns (address moduleAddress, bytes32 initCodeHash, bytes32 contractCodeHash)
    {
        bytes memory initCode = abi.encodePacked(createCode, params);
        // this enforces, that constructor params were supplied via params argument
        // if params were abi.encodePacked in createCode, this will revert
        if (calcAddress(initCode, salt) == calcAddress(createCode, salt)) revert InvalidCode();
        initCodeHash = keccak256(initCode);

        assembly {
            moduleAddress := create2(0, add(initCode, 0x20), mload(initCode), salt)
            contractCodeHash := extcodehash(moduleAddress)
            // If the contract was not created successfully, the transaction is reverted.
            if iszero(extcodesize(moduleAddress)) { revert(0, 0) }
        }
    }

    function calcAddress(bytes memory _code, uint256 _salt) internal view returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_code)));
        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    error InvalidCode();
}
