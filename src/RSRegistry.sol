// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// @author zeroknots | Rhinestone.wtf

// Importing external dependencies.

// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

import { IRSAuthority } from "./interface/IRSAuthority.sol";

// Helper functions for this contract
import { RSRegistryLib } from "./lib/RSRegistryLib.sol";

// A registry contract for managing various types of records, including contract implementations,
contract RSRegistry {
    using RSRegistryLib for address;
    using RSRegistryLib for bytes;

    // Struct that holds information about the verifier.
    struct VerifierInfo {
        address signer;
        string url;
    }

    enum AttestationState {
        None,
        Pending,
        Rejected,
        Revoked,
        Compromised,
        Verified
    }

    // Struct that holds a record of a attestation process.
    struct Attestation {
        uint8 risk;
        uint8 confidence;
        AttestationState state;
        // uint32 timestamp;
        bytes32 codeHash;
        bytes data;
    }

    // Struct that represents a contract artifact.
    struct ContractArtifact {
        address implementation;
        bytes32 codeHash;
        bytes32 deployParamsHash;
        address sender;
        bytes data;
    }

    /*//////////////////////////////////////////////////////////////
                              STORAGE
    //////////////////////////////////////////////////////////////*/
    // Instance of Hashi's Yaho contract.
    Yaho public yaho;
    // Instance of Hashi's Yaru contract.
    Yaru public yaru;

    // The address of the L1 registry contract. Leave address(0) if this contract is on L1.
    address public l1Registry;

    // Mapping from signer to verifier info.
    mapping(address authority => VerifierInfo) public authorities;

    // Mapping from contract address to contract artifact.
    mapping(address contractAddr => ContractArtifact) public contracts;

    // Mapping from contract address and authority to attestation record.
    mapping(address contractAddr => mapping(address authority => Attestation)) attestations;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    // Event triggered when a contract is deployed.
    event Deployment(address indexed implementation, bytes32 codeHash);
    // Event triggered when a contract is registered.
    event Registration(address indexed implementation, bytes32 codeHash);
    // Event triggered when a contract is verified.
    event attestation(
        address indexed implementation, address indexed authority, Attestation attestation
    );
    // Event triggered when a contract is propagated.
    event Propagation(address indexed implementation, address indexed authority);

    /// @notice Contract constructor.
    /// @param _yaho Instance of the Yaho contract.
    /// @param _yaru Instance of the Yaru contract.
    /// @param _l1Registry The address of the L1 registry contract. Leave address(0) if instance is on L1
    constructor(Yaho _yaho, Yaru _yaru, address _l1Registry) {
        yaho = _yaho;
        yaru = _yaru;
        l1Registry = _l1Registry;
    }

    /// @notice Verifies a contract.
    /// @dev Stores the attestation record in the attestations mapping.
    /// @param contractAddr The address of the contract to be verified.
    /// @param risk The risk level associated with the contract.
    /// @param confidence The confidence level in the attestation.
    /// @param data Additional data related to the attestation.
    /// @param codeHash The code hash of the contract.
    function verify(
        address contractAddr,
        uint8 risk,
        uint8 confidence,
        bytes memory data,
        bytes32 codeHash,
        AttestationState state
    )
        external
    {
        bytes32 currentCodeHash = contractAddr.codeHash();
        if (codeHash != currentCodeHash) revert InvalidCodeHash(currentCodeHash, codeHash);

        Attestation memory attestationRecord = Attestation({
            risk: risk,
            confidence: confidence,
            state: state,
            codeHash: codeHash,
            data: data
        });

        attestations[contractAddr][msg.sender] = attestationRecord;

        emit attestation(contractAddr, msg.sender, attestationRecord);
    }

    /// @notice Registers a contract.
    /// @param contractAddr The address of the contract to be registered.
    /// @param deployParams abi.encode() params supplied for constructor of contract
    /// @param data additonal data provided for registration
    /// @return contractCodeHash The code hash of the registered contract.
    function register(
        address contractAddr,
        bytes memory deployParams,
        bytes calldata data
    )
        public
        returns (bytes32 contractCodeHash)
    {
        // ensures that contract exists. Will revert if EOA or address(0) is provided
        contractCodeHash = contractAddr.codeHash();
        if (contracts[contractAddr].implementation != address(0)) {
            revert AlreadyRegistered(contractAddr);
        }
        _register({
            contractAddr: contractAddr,
            codeHash: contractCodeHash,
            sender: address(0),
            deployParams: deployParams,
            data: data
        });

        emit Registration(contractAddr, contractCodeHash);
    }

    /// @notice Deploys a contract.
    /// @param code The creationCode for the contract to be deployed.
    /// @param deployParams abi.encode() params supplied for constructor of contract
    /// @param salt The salt for creating the contract.
    /// @param data additonal data provided for registration
    /// @return contractAddr The address of the deployed contract.
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data
    )
        external
        returns (address contractAddr)
    {
        bytes32 initCodeHash; // hash packed(creationCode, deployParams)
        bytes32 contractCodeHash; //  hash of contract bytecode
        (contractAddr, initCodeHash, contractCodeHash) = code.deploy(deployParams, salt);
        _register({
            contractAddr: contractAddr,
            codeHash: contractCodeHash,
            sender: msg.sender,
            deployParams: deployParams,
            data: data
        });

        emit Deployment(contractAddr, contractCodeHash);
    }

    function pollAuthorities(
        address[] calldata _authority,
        address contractAddr
    )
        public
        view
        returns (Attestation[] memory attestations_)
    {
        uint256 authorityLength = _authority.length;
        bytes32 currentCodeHash = contractAddr.codeHash();
        attestations_ = new Attestation[](authorityLength);
        for (uint256 i; i < authorityLength; ++i) {
            attestations_[i] = IRSAuthority(_authority[i]).getAttestation(
                contractAddr, msg.sender, currentCodeHash
            );

            // revert if any of the chosen authorities flagged the contract as compromised
            if (attestations_[i].state < AttestationState.Verified) {
                revert SecurityAlert(contractAddr, _authority[i]);
            }
        }
    }

    /// @notice Queries a contract's attestation status.
    /// @param contractAddr The address of the contract to be queried.
    /// @param authority The authority conducting the attestation.
    /// @param acceptedRisk The accepted risk level.
    /// @return true if the attestation status is acceptable, false otherwise.
    function queryRegistry(
        address contractAddr,
        address authority,
        uint8 acceptedRisk
    )
        external
        view
        returns (bool)
    {
        Attestation storage attestation = attestations[contractAddr][authority];

        if (attestation.risk > acceptedRisk) revert RiskTooHigh(attestation.risk);

        // check code hash
        bytes32 currentCodeHash = contractAddr.codeHash();
        if (currentCodeHash != attestation.codeHash) {
            revert InvalidCodeHash(currentCodeHash, attestation.codeHash);
        }
        if (currentCodeHash != contracts[contractAddr].codeHash) {
            revert InvalidCodeHash(currentCodeHash, attestation.codeHash);
        }

        return true;
    }

    /// @notice Dispatches a attestation message to another chain.
    /// @param implementation The address of the contract implementation.
    /// @param authority The authority address responsible for the attestation.
    /// @param toChainId The chain id to dispatch the message to.
    /// @param to The address to send the message to.
    /// @return messages An array of the sent messages.
    /// @return messageIds An array of the sent message IDs.
    function dispatchAttestation(
        address implementation,
        address authority,
        uint256 toChainId,
        address to
    )
        external
        returns (Message[] memory messages, bytes32[] memory messageIds)
    {
        // Get the attestation record for the contract and the authority.
        Attestation memory attestationRecord = attestations[implementation][authority];
        if (attestationRecord.codeHash == bytes32(0)) {
            revert InvalidAttestation(implementation, authority);
        }

        // Encode the attestation record into a data payload.
        bytes memory callReceiveFnOnL2 = abi.encodeWithSelector(
            this.receiveL1attestation.selector,
            implementation,
            authority,
            attestationRecord,
            contracts[implementation]
        );

        // Prepare the message for dispatch.
        messages = new Message[](1);
        messages[0] = Message({ to: to, toChainId: toChainId, data: callReceiveFnOnL2 });

        messageIds = new bytes32[](1);
        // Dispatch message to selected L2
        messageIds = yaho.dispatchMessages(messages);

        emit Propagation(implementation, authority);
    }

    /// @notice Receives a attestation message from L1.
    /// @dev This function should be called only by a valid caller.
    /// @param contractAddr The address of the contract that was verified.
    /// @param authority The authority address responsible for the attestation.
    /// @param attestationRecord The attestationRecord data.
    function receiveL1attestation(
        address contractAddr,
        address authority,
        Attestation calldata attestationRecord,
        ContractArtifact calldata contractArtifact
    )
        external
        onlyHashi
    {
        // check if contract has the same bytecode on L2 as on L1
        bytes32 currentCodeHash = contractAddr.codeHash();
        if (currentCodeHash != attestationRecord.codeHash) {
            revert InvalidCodeHash(currentCodeHash, attestationRecord.codeHash);
        }
        // Store the received attestation record.
        attestations[contractAddr][authority] = attestationRecord;
        if (contracts[contractAddr].implementation == address(0)) {
            contracts[contractAddr] = contractArtifact;
        }
        emit attestation(contractAddr, authority, attestationRecord);
    }

    /// @notice Adds an authority for attestation purposes.
    /// @dev Stores the sender's address and a URL in the VerifierInfo struct.
    /// @param url The URL related to the verifier.
    function addAuthority(string memory url) external {
        authorities[msg.sender] = VerifierInfo(msg.sender, url);
    }

    // Modifier that checks the validity of the caller and sender.
    modifier onlyHashi() {
        if (yaru.sender() != l1Registry) revert InvalidSender(address(this), yaru.sender());
        if (msg.sender != address(yaru)) revert InvalidCaller(address(this), msg.sender);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERAL
    //////////////////////////////////////////////////////////////*/
    function _register(
        address contractAddr,
        bytes32 codeHash,
        address sender,
        bytes memory deployParams,
        bytes memory data
    )
        internal
    {
        contracts[contractAddr] = ContractArtifact({
            implementation: contractAddr,
            codeHash: codeHash,
            sender: sender,
            deployParamsHash: keccak256(deployParams),
            data: data
        });
    }
}

/*//////////////////////////////////////////////////////////////
                          Errors
//////////////////////////////////////////////////////////////*/
error InvalidChainId(); // Emitted when the provided chain ID is invalid.
error InvalidBridgeTarget(); // Emitted when the bridge target is invalid.
error InvalidSender(address contractAddr, address sender); // Emitted when the sender address is invalid.
error InvalidCaller(address contractAddr, address yaruSender); // Emitted when the caller is not the Yaru contract.
error InvalidAttestation(address contractAddr, address authority); // Emitted when the attestation is invalid.
error InvalidCodeHash(bytes32 expected, bytes32 actual); // Emitted when the contract hash is invalid.
error RiskTooHigh(uint8 risk); // Emitted when the risk level is too high.
error AlreadyRegistered(address contractAddr); // Emitted when the contract is already registered.
error SecurityAlert(address contractAddr, address authority);
