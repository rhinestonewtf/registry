// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IRSModuleRegistry, Module } from "./IRSModuleRegistry.sol";
import { InvalidSchema } from "./Common.sol";
import { IRSSchema, SchemaRecord } from "./IRSSchema.sol";
import { RSSchema } from "./RSSchema.sol";

/**
 * @title RSModuleRegistry
 *
 * @dev The RSModuleRegistry contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IRSModuleRegistry interface and the RSSchema contract,
 * providing the actual implementation for the interface and extending the functionality of the RSSchema contract.
 *
 * @dev The primary responsibility of the RSModuleRegistry is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the RSModuleRegistry. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional data are stored in a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev The `deploy` function is used to deploy a new module. The code of the module, parameters for deployment (constructor arguments),
 * a salt for creating the contract, additional data for registration, and a schema ID under which to register the contract are
 * all passed as arguments to this function. This function first checks if the provided schema ID is valid and then deploys the contract.
 * Once the contract is successfully deployed, the details are stored in the `_modules` mapping and a `Deployment` event is emitted.
 *
 * @dev Furthermore, the RSModuleRegistry contract utilizes the Ethereum `CREATE2` opcode in its `_deploy` function for deploying
 * contracts. This opcode allows creating a contract with a deterministic address, which is calculated in the `_calcAddress` function.
 * This approach provides flexibility and advanced patterns in contract interactions, like the ability to show a contract’s address
 * before it is mined.
 *
 * @dev In conclusion, the RSModuleRegistry is a central part of a system to manage, deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 */
contract RSModuleRegistry is IRSModuleRegistry, RSSchema {
    mapping(address moduleAddress => Module) internal _modules;

    /**
     * @inheritdoc IRSModuleRegistry
     */
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data,
        bytes32 schemaId
    )
        external
        returns (address moduleAddr)
    {
        // Check if the provided schemaId exists
        if (schemaId != getSchema(schemaId).uid) revert InvalidSchema();

        bytes32 initCodeHash; // Hash of the contract creation code and deployment parameters
        bytes32 contractCodeHash; //  Hash of contract bytecode
        (moduleAddr, initCodeHash, contractCodeHash) = _deploy(code, deployParams, salt);

        // Store module data in _modules mapping
        _modules[moduleAddr] = Module({
            implementation: moduleAddr,
            codeHash: contractCodeHash,
            schemaId: schemaId,
            sender: msg.sender,
            deployParamsHash: keccak256(deployParams),
            data: data
        });

        emit Deployment(moduleAddr, contractCodeHash); // Emit a deployment event
    }

    /**
     * @dev Deploys a contract using the CREATE2 opcode.
     *
     * @param createCode The creationCode for the contract.
     * @param params The parameters for creating the contract. If the contract has a constructor, this MUST be provided.
     * @param salt The salt for creating the contract.
     * @return moduleAddress The address of the deployed contract.
     * @return initCodeHash Hash of the contract creation code and deployment parameters.
     * @return contractCodeHash hash of deployed bytecode.
     */
    function _deploy(
        bytes memory createCode,
        bytes memory params,
        uint256 salt
    )
        internal
        returns (address moduleAddress, bytes32 initCodeHash, bytes32 contractCodeHash)
    {
        bytes memory initCode = abi.encodePacked(createCode, params);
        // Check if the provided constructor parameters are part of initCode or just packed in createCode
        // this enforces, that constructor params were supplied via params argument
        if (_calcAddress(initCode, salt) == _calcAddress(createCode, salt)) {
            revert InvalidDeployment();
        }
        initCodeHash = keccak256(initCode);

        // Create the contract using the CREATE2 opcode
        assembly {
            moduleAddress := create2(0, add(initCode, 0x20), mload(initCode), salt)
            contractCodeHash := extcodehash(moduleAddress)
            // If the contract was not created successfully, the transaction is reverted.
            if iszero(extcodesize(moduleAddress)) { revert(0, 0) }
        }
    }

    /**
     * @dev Calculates the deterministic address of a contract that would be deployed using the CREATE2 opcode.
     *
     * @param _code The contract code that would be deployed.
     * @param _salt A salt used for the address calculation.
     * @return The address that the contract would be deployed at if the CREATE2 opcode was called with the specified _code and _salt.
     */
    function _calcAddress(bytes memory _code, uint256 _salt) public view returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_code)));
        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }
}
