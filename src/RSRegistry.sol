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

import "forge-std/console2.sol";

// A registry contract for managing various types of records, including contract implementations,
contract RSRegistry {
    using RSRegistryLib for address;
    using RSRegistryLib for bytes;
    using RSRegistryLib for IRSAuthority;

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
        // uint32 issuedAt;
        // uint32 validUntil;
        bytes32 codeHash;
        bytes data;
    }

    // Struct that represents a contract artifact.
    struct Module {
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
    mapping(address moduleAddr => Module) public modules;

    // Mapping from contract address and authority to attestation record.
    mapping(address moduleAddr => mapping(address authority => Attestation)) attestations;

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
    /// @param moduleAddr The address of the contract to be verified.
    /// @param risk The risk level associated with the contract.
    /// @param confidence The confidence level in the attestation.
    /// @param data Additional data related to the attestation.
    /// @param codeHash The code hash of the contract.
    function verify(
        address moduleAddr,
        uint8 risk,
        uint8 confidence,
        bytes memory data,
        bytes32 codeHash,
        AttestationState state
    )
        external
    {
        bytes32 currentCodeHash = moduleAddr.codeHash();
        if (codeHash != currentCodeHash) revert InvalidCodeHash(currentCodeHash, codeHash);

        Attestation memory attestationRecord = Attestation({
            risk: risk,
            confidence: confidence,
            state: state,
            codeHash: codeHash,
            data: data
        });

        attestations[moduleAddr][msg.sender] = attestationRecord;

        emit attestation(moduleAddr, msg.sender, attestationRecord);
    }

    /// @notice Registers a contract.
    /// @param moduleAddr The address of the contract to be registered.
    /// @param deployParams abi.encode() params supplied for constructor of contract
    /// @param data additonal data provided for registration
    /// @return contractCodeHash The code hash of the registered contract.
    function register(
        address moduleAddr,
        bytes memory deployParams,
        bytes calldata data
    )
        public
        returns (bytes32 contractCodeHash)
    {
        // ensures that contract exists. Will revert if EOA or address(0) is provided
        contractCodeHash = moduleAddr.codeHash();
        if (modules[moduleAddr].implementation != address(0)) {
            revert AlreadyRegistered(moduleAddr);
        }
        _register({
            moduleAddr: moduleAddr,
            codeHash: contractCodeHash,
            sender: address(0),
            deployParams: deployParams,
            data: data
        });

        emit Registration(moduleAddr, contractCodeHash);
    }

    /// @notice Deploys a contract.
    /// @param code The creationCode for the contract to be deployed.
    /// @param deployParams abi.encode() params supplied for constructor of contract
    /// @param salt The salt for creating the contract.
    /// @param data additonal data provided for registration
    /// @return moduleAddr The address of the deployed contract.
    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes calldata data
    )
        external
        returns (address moduleAddr)
    {
        bytes32 initCodeHash; // hash packed(creationCode, deployParams)
        bytes32 contractCodeHash; //  hash of contract bytecode
        (moduleAddr, initCodeHash, contractCodeHash) = code.deploy(deployParams, salt);
        _register({
            moduleAddr: moduleAddr,
            codeHash: contractCodeHash,
            sender: msg.sender,
            deployParams: deployParams,
            data: data
        });

        emit Deployment(moduleAddr, contractCodeHash);
    }

    function _tryPullAttestation(
        IRSAuthority authority,
        address module,
        bytes32 codeHash
    )
        internal
        view
        returns (Attestation memory attestation_)
    {
        (, bytes memory returnData) = address(authority).staticcall(
            abi.encodePacked(
                IRSAuthority.getAttestation.selector, abi.encode(module, msg.sender, codeHash)
            )
        );

        if (returnData.length > 0) {
            attestation_ = abi.decode(returnData, (Attestation));
        } else {
            attestation_ = Attestation({
                risk: 0,
                confidence: 0,
                state: AttestationState.None,
                codeHash: codeHash,
                data: ""
            });
        }
    }

    function fetchAttestation(
        IRSAuthority[] calldata _authority,
        address moduleAddr,
        uint8 threshold
    )
        external
        view
        returns (Attestation[] memory attestations_)
    {
        uint256 authorityLength = _authority.length;
        bytes32 currentCodeHash = moduleAddr.codeHash();
        if (threshold > authorityLength || threshold == 0) threshold = uint8(authorityLength);
        attestations_ = new Attestation[](authorityLength);

        for (uint256 i; i < authorityLength; ++i) {
            attestations_[i] = _tryPullAttestation(_authority[i], moduleAddr, currentCodeHash);
            if (attestations_[i].state == AttestationState.Verified) --threshold;
            if (threshold == 0) break;
        }
        if (threshold != 0) revert ThresholdNotReached(threshold, moduleAddr);
    }

    /// @notice Queries a contract's attestation status.
    /// @param moduleAddr The address of the contract to be queried.
    /// @param authority The authority conducting the attestation.
    /// @param acceptedRisk The accepted risk level.
    /// @return true if the attestation status is acceptable, false otherwise.

    function fetchAttestation(
        address moduleAddr,
        address authority,
        uint8 acceptedRisk
    )
        external
        view
        returns (bool)
    {
        Attestation storage attestationStor = attestations[moduleAddr][authority];

        if (attestationStor.risk > acceptedRisk) revert RiskTooHigh(attestationStor.risk);

        // check code hash
        bytes32 currentCodeHash = moduleAddr.codeHash();
        if (currentCodeHash != attestationStor.codeHash) {
            revert InvalidCodeHash(currentCodeHash, attestationStor.codeHash);
        }
        if (currentCodeHash != modules[moduleAddr].codeHash) {
            revert InvalidCodeHash(currentCodeHash, attestationStor.codeHash);
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
            modules[implementation]
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
    /// @param moduleAddr The address of the contract that was verified.
    /// @param authority The authority address responsible for the attestation.
    /// @param attestationRecord The attestationRecord data.
    function receiveL1attestation(
        address moduleAddr,
        address authority,
        Attestation calldata attestationRecord,
        Module calldata contractArtifact
    )
        external
        onlyHashi
    {
        // check if contract has the same bytecode on L2 as on L1
        bytes32 currentCodeHash = moduleAddr.codeHash();
        if (currentCodeHash != attestationRecord.codeHash) {
            revert InvalidCodeHash(currentCodeHash, attestationRecord.codeHash);
        }
        // Store the received attestation record.
        attestations[moduleAddr][authority] = attestationRecord;
        if (modules[moduleAddr].implementation == address(0)) {
            modules[moduleAddr] = contractArtifact;
        }
        emit attestation(moduleAddr, authority, attestationRecord);
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
        address moduleAddr,
        bytes32 codeHash,
        address sender,
        bytes memory deployParams,
        bytes memory data
    )
        internal
    {
        modules[moduleAddr] = Module({
            implementation: moduleAddr,
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
error InvalidSender(address moduleAddr, address sender); // Emitted when the sender address is invalid.
error InvalidCaller(address moduleAddr, address yaruSender); // Emitted when the caller is not the Yaru contract.
error InvalidAttestation(address moduleAddr, address authority); // Emitted when the attestation is invalid.
error InvalidCodeHash(bytes32 expected, bytes32 actual); // Emitted when the contract hash is invalid.
error RiskTooHigh(uint8 risk); // Emitted when the risk level is too high.
error AlreadyRegistered(address moduleAddr); // Emitted when the contract is already registered.
error SecurityAlert(address moduleAddr, address authority);
error ThresholdNotReached(uint256 threshold, address moduleAddr);
