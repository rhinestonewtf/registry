// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IRegistry {
    event Attested(
        address indexed moduleAddr,
        address indexed attester,
        bytes32 schema,
        address indexed dataPointer
    );
    event EIP712DomainChanged();
    event ModuleDeployed(address indexed implementation, bytes32 indexed salt, bytes32 resolver);
    event ModuleDeployedExternalFactory(
        address indexed implementation, address indexed factory, bytes32 resolver
    );
    event ModuleRegistration(address indexed implementation, bytes32 resolver);
    event NewSchemaResolver(bytes32 indexed uid, address resolver);
    event Revoked(address indexed moduleAddr, address indexed attester, bytes32 indexed schema);
    event RevokedOffchain(address indexed revoker, bytes32 indexed data, uint64 indexed timestamp);
    event SchemaRegistered(bytes32 indexed uid, address registerer);
    event SchemaResolverRegistered(bytes32 indexed uid, address registerer);
    event Timestamped(bytes32 indexed data, uint64 indexed timestamp);

    struct AttestationRecord {
        bytes32 schemaUID;
        address moduleAddr;
        address attester;
        uint48 time;
        uint48 expirationTime;
        uint48 revocationTime;
        address dataPointer;
    }

    struct AttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData data;
    }

    struct AttestationRequestData {
        address moduleAddr;
        uint48 expirationTime;
        uint256 value;
        bytes data;
    }

    struct SignedAttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData data;
        bytes signature;
        address attester;
    }

    struct SignedRevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData data;
        bytes signature;
        address revoker;
    }

    struct ModuleRecord {
        bytes32 resolverUID;
        address implementation;
        address sender;
        bytes data;
    }

    struct MultiAttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData[] data;
    }

    struct MultiSignedAttestationRequest {
        bytes32 schemaUID;
        AttestationRequestData[] data;
        bytes[] signatures;
        address attester;
    }

    struct MultiSignedRevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData[] data;
        bytes[] signatures;
        address revoker;
    }

    struct MultiRevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData[] data;
    }

    struct ResolverRecord {
        address resolver;
        address schemaOwner;
    }

    struct RevocationRequest {
        bytes32 schemaUID;
        RevocationRequestData data;
    }

    struct RevocationRequestData {
        address moduleAddr;
        address attester;
        uint256 value;
    }

    struct SchemaRecord {
        uint48 registeredAt;
        address validator;
        string schema;
    }

    function attest(SignedAttestationRequest memory signedRequest) external payable;
    function attest(AttestationRequest memory request) external payable;
    function check(
        address module,
        address attester
    )
        external
        view
        returns (uint48 listedAt, uint48 revokedAt);
    function deploy(
        bytes memory code,
        bytes memory deployParams,
        bytes32 salt,
        bytes memory data,
        bytes32 resolverUID
    )
        external
        payable
        returns (address moduleAddr);
    function deployC3(
        bytes memory code,
        bytes memory deployParams,
        bytes32 salt,
        bytes memory data,
        bytes32 resolverUID
    )
        external
        payable
        returns (address moduleAddr);
    function deployViaFactory(
        address factory,
        bytes memory callOnFactory,
        bytes memory data,
        bytes32 resolverUID
    )
        external
        payable
        returns (address moduleAddr);
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
    function findAttestation(
        address module,
        address attesters
    )
        external
        view
        returns (AttestationRecord memory attestation);
    function findAttestations(
        address module,
        address[] memory attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations);
    function getAttestTypeHash() external pure returns (bytes32);
    function getAttestationDigest(
        AttestationRequestData memory attData,
        bytes32 schemaUID,
        uint256 nonce
    )
        external
        view
        returns (bytes32 digest);
    function getAttestationDigest(
        AttestationRequestData memory attData,
        bytes32 schemaUID,
        address attester
    )
        external
        view
        returns (bytes32 digest);
    function getDomainSeparator() external view returns (bytes32);
    function getModule(address moduleAddress) external view returns (ModuleRecord memory);
    function getName() external view returns (string memory);
    function getNonce(address account) external view returns (uint256);
    function getResolver(bytes32 uid) external view returns (ResolverRecord memory);
    function getRevocationDigest(
        RevocationRequestData memory revData,
        bytes32 schemaUID,
        address revoker
    )
        external
        view
        returns (bytes32 digest);
    function getRevocationDigest(
        RevocationRequestData memory revData,
        bytes32 schemaUID,
        uint256 nonce
    )
        external
        view
        returns (bytes32 digest);
    function getRevokeTypeHash() external pure returns (bytes32);
    function getSchema(bytes32 uid) external view returns (SchemaRecord memory);
    function multiAttest(MultiSignedAttestationRequest[] memory multiSignedRequests)
        external
        payable;
    function multiAttest(MultiAttestationRequest[] memory multiRequests) external payable;
    function multiRevoke(MultiRevocationRequest[] memory multiRequests) external payable;
    function multiRevoke(MultiSignedRevocationRequest[] memory multiSignedRequests)
        external
        payable;
    function register(bytes32 resolverUID, address moduleAddress, bytes memory data) external;
    function registerResolver(address _resolver) external returns (bytes32);
    function registerSchema(string memory schema, address validator) external returns (bytes32);
    function revoke(RevocationRequest memory request) external payable;
    function setResolver(bytes32 uid, address resolver) external;
    function verify(address module, address[] memory attesters, uint256 threshold) external view;
    function verifyUnsafe(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view;
}
