// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

// @author zeroknots | Rhinestone.wtf

// Importing external dependencies.

// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

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

    // Struct that holds a record of a verification process.
    struct VerificationRecord {
        uint8 risk;
        uint8 confidence;
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

    // Mapping from contract address and authority to verification record.
    mapping(address contractAddr => mapping(address authority => VerificationRecord)) verifications;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    // Event triggered when a contract is deployed.
    event Deployment(address indexed implementation, bytes32 codeHash);
    // Event triggered when a contract is registered.
    event Registration(address indexed implementation, bytes32 codeHash);
    // Event triggered when a contract is verified.
    event Verification(
        address indexed implementation, address indexed authority, VerificationRecord verification
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

    // Modifier that checks the validity of the caller and sender.
    modifier onlyHashi() {
        if (yaru.sender() != l1Registry) revert InvalidSender(address(this), yaru.sender());
        if (msg.sender != address(yaru)) revert InvalidCaller(address(this), msg.sender);
        _;
    }

    /// @notice Adds an authority for verification purposes.
    /// @dev Stores the sender's address and a URL in the VerifierInfo struct.
    /// @param url The URL related to the verifier.
    function addAuthority(string memory url) external {
        authorities[msg.sender] = VerifierInfo(msg.sender, url);
    }

    /// @notice Verifies a contract.
    /// @dev Stores the verification record in the verifications mapping.
    /// @param contractAddr The address of the contract to be verified.
    /// @param risk The risk level associated with the contract.
    /// @param confidence The confidence level in the verification.
    /// @param data Additional data related to the verification.
    /// @param codeHash The code hash of the contract.
    function verify(
        address contractAddr,
        uint8 risk,
        uint8 confidence,
        bytes memory data,
        bytes32 codeHash
    )
        external
    {
        bytes32 currentCodeHash = contractAddr.codeHash();
        if (codeHash != currentCodeHash) revert InvalidCodeHash(currentCodeHash, codeHash);

        VerificationRecord memory verificationRecord = VerificationRecord({
            risk: risk,
            confidence: confidence,
            codeHash: codeHash,
            data: data
        });

        verifications[contractAddr][msg.sender] = verificationRecord;

        emit Verification(contractAddr, msg.sender, verificationRecord);
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

    /// @notice Queries a contract's verification status.
    /// @param contractAddr The address of the contract to be queried.
    /// @param authority The authority conducting the verification.
    /// @param acceptedRisk The accepted risk level.
    /// @return true if the verification status is acceptable, false otherwise.
    function query(
        address contractAddr,
        address authority,
        uint8 acceptedRisk
    )
        external
        view
        returns (bool)
    {
        VerificationRecord storage verification = verifications[contractAddr][authority];

        if (verification.risk > acceptedRisk) revert RiskTooHigh(verification.risk);

        // check code hash
        bytes32 currentCodeHash = contractAddr.codeHash();
        if (currentCodeHash != verification.codeHash) {
            revert InvalidCodeHash(currentCodeHash, verification.codeHash);
        }
        if (currentCodeHash != contracts[contractAddr].codeHash) {
            revert InvalidCodeHash(currentCodeHash, verification.codeHash);
        }

        return true;
    }

    /// @notice Dispatches a verification message to another chain.
    /// @param implementation The address of the contract implementation.
    /// @param authority The authority address responsible for the verification.
    /// @param toChainId The chain id to dispatch the message to.
    /// @param to The address to send the message to.
    /// @return messages An array of the sent messages.
    /// @return messageIds An array of the sent message IDs.
    function dispatchVerification(
        address implementation,
        address authority,
        uint256 toChainId,
        address to
    )
        external
        returns (Message[] memory messages, bytes32[] memory messageIds)
    {
        // Get the verification record for the contract and the authority.
        VerificationRecord memory verificationRecord = verifications[implementation][authority];
        if (verificationRecord.codeHash == bytes32(0)) {
            revert InvalidVerification(implementation, authority);
        }

        // Encode the verification record into a data payload.
        bytes memory callReceiveFnOnL2 = abi.encodeWithSelector(
            this.receiveL1Verification.selector,
            implementation,
            authority,
            verificationRecord,
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

    /// @notice Receives a verification message from L1.
    /// @dev This function should be called only by a valid caller.
    /// @param contractAddr The address of the contract that was verified.
    /// @param authority The authority address responsible for the verification.
    /// @param verificationRecord The VerificationRecord data.
    function receiveL1Verification(
        address contractAddr,
        address authority,
        VerificationRecord calldata verificationRecord,
        ContractArtifact calldata contractArtifact
    )
        external
        onlyHashi
    {
        // check if contract has the same bytecode on L2 as on L1
        bytes32 currentCodeHash = contractAddr.codeHash();
        if (currentCodeHash != verificationRecord.codeHash) {
            revert InvalidCodeHash(currentCodeHash, verificationRecord.codeHash);
        }
        // Store the received verification record.
        verifications[contractAddr][authority] = verificationRecord;
        if (contracts[contractAddr].implementation == address(0)) {
            contracts[contractAddr] = contractArtifact;
        }
        emit Verification(contractAddr, authority, verificationRecord);
    }
}

/*//////////////////////////////////////////////////////////////
                          Errors
//////////////////////////////////////////////////////////////*/
error InvalidChainId(); // Emitted when the provided chain ID is invalid.
error InvalidBridgeTarget(); // Emitted when the bridge target is invalid.
error InvalidSender(address contractAddr, address sender); // Emitted when the sender address is invalid.
error InvalidCaller(address contractAddr, address yaruSender); // Emitted when the caller is not the Yaru contract.
error InvalidVerification(address contractAddr, address authority); // Emitted when the verification is invalid.
error InvalidCodeHash(bytes32 expected, bytes32 actual); // Emitted when the contract hash is invalid.
error RiskTooHigh(uint8 risk); // Emitted when the risk level is too high.
error AlreadyRegistered(address contractAddr); // Emitted when the contract is already registered.
