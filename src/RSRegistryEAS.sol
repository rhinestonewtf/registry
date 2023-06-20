// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@eas/EAS.sol";
import "@eas/Common.sol";
import "@eas/IEAS.sol";
import "@eas/ISchemaRegistry.sol";

// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

import { RSRegistryLib } from "./lib/RSRegistryLib.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RSRegistryEAS {
    using RSRegistryLib for bytes;
    using RSRegistryLib for address;

    EAS eas;
    ISchemaRegistry schemaRegistry;

    struct RegistryData {
        bytes32 schemaId;
        address moduleAddr;
        mapping(address attester => bytes32) attestations;
    }

    mapping(address moduleAddr => RegistryData) public moduleDB;

    event NewAttestation(address indexed module, bytes32 schemaId, bytes32 attestationId);

    constructor(address _eas) {
        eas = EAS(_eas);
        schemaRegistry = ISchemaRegistry(eas.getSchemaRegistry());
    }

    function register(address _moduleAddr, bytes32 _schemaId) public {
        // ensure  schema ID exists
        SchemaRecord memory schemaRecord = schemaRegistry.getSchema(_schemaId);
        require(schemaRecord.uid == _schemaId, "Invalid Schema");
        moduleDB[_moduleAddr].schemaId = _schemaId;
        moduleDB[_moduleAddr].moduleAddr = _moduleAddr;
    }

    function deploy(
        bytes calldata code,
        bytes calldata deployParams,
        uint256 salt,
        bytes32 schemaId
    )
        external
        returns (address moduleAddr)
    {
        bytes32 initCodeHash; // hash packed(creationCode, deployParams)
        bytes32 contractCodeHash; //  hash of contract bytecode
        (moduleAddr, initCodeHash, contractCodeHash) = code.deploy(deployParams, salt);
        register(moduleAddr, schemaId);
    }

    function attest(
        address _moduleAddr,
        AttestationRequestData memory _attestationData,
        EIP712Signature memory _signature
    )
        public
        returns (bytes32 attestationId)
    {
        bytes32 schemaId = moduleDB[_moduleAddr].schemaId;
        require(schemaId != EMPTY_UID, "Module not registered");
        DelegatedAttestationRequest memory attestation = DelegatedAttestationRequest({
            schema: schemaId,
            data: _attestationData,
            signature: _signature,
            attester: msg.sender
        });

        attestationId = eas.attestByDelegation(attestation);
        moduleDB[_moduleAddr].attestations[msg.sender] = attestationId;

        emit NewAttestation(_moduleAddr, schemaId, attestationId);
    }

    function getAttestationDigest(
        AttestationRequestData memory attData,
        bytes32 schemaUid,
        address attester
    )
        public
        view
        returns (bytes32 digest)
    {
        bytes32 ATTEST_TYPEHASH = eas.getAttestTypeHash();
        uint256 nonce = eas.getNonce(attester);
        bytes32 structHash = keccak256(
            abi.encode(
                ATTEST_TYPEHASH,
                schemaUid,
                attData.recipient,
                attData.expirationTime,
                attData.revocable,
                attData.refUID,
                keccak256(attData.data),
                nonce
            )
        );
        digest = ECDSA.toTypedDataHash(eas.getDomainSeparator(), structHash);
    }

    function validate(
        address _moduleAddr,
        address _attester
    )
        public
        view
        returns (Attestation memory attestation)
    {
        bytes32 attestationId = moduleDB[_moduleAddr].attestations[_attester];
        attestation = validate(_moduleAddr, attestationId);
    }

    function validate(
        address _moduleAddr,
        address[] memory _attesters
    )
        public
        view
        returns (Attestation[] memory attestations)
    {
        uint256 length = _attesters.length;
        attestations = new Attestation[](length);
        for (uint256 i; i < length; ++i) {
            attestations[i] = validate(_moduleAddr, _attesters[i]);
        }
    }

    function validate(
        address _moduleAddr,
        bytes32 _attestationId
    )
        public
        view
        returns (Attestation memory attestation)
    {
        bytes32 schemaId = moduleDB[_moduleAddr].schemaId;
        attestation = eas.getAttestation(_attestationId);
        require(attestation.schema == schemaId, "Invalid Schema");
        require(attestation.expirationTime < block.timestamp, "Attestation expired");
        require(attestation.recipient == _moduleAddr, "Invalid recipient");
        require(attestation.revocationTime == 0, "Attestation revoked");

        // recursion is a bit ugly, but it might be a good way to validate the attestation chain
        if (attestation.refUID != EMPTY_UID) {
            validate(_moduleAddr, attestation.refUID);
        }
    }

    function dispatchAttestastion(
        address module,
        address authority,
        address to,
        uint256 toChainId
    )
        external
        returns (Message[] memory messages, bytes32[] memory messageIds)
    {
        bytes32 attestationId = moduleDB[module].attestations[authority];
        Attestation memory attestation = eas.getAttestation(attestationId);

        bytes memory propagationCalldata = abi.encodeWithSelector(
            this.receiveAttestation.selector, module, authority, module.codeHash(), attestation
        );

        messages = new Message[](1);
        messages[0] = Message({ to: to, toChainId: toChainId, data: propagationCalldata });

        messageIds = new bytes32[](1);
        // Dispatch message to selected L2
    }

    function receiveAttestation(
        address moduleAddr,
        address authority,
        bytes32 codeHash,
        Attestation calldata attestation
    )
        external
    { }
}
