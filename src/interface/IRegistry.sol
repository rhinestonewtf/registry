// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../Common.sol";
import "../DataTypes.sol";
import "../base/Attestation.sol";
import "./IAttestation.sol";
import "./ISchema.sol";
import "../external/IResolver.sol";

interface IRegistry {
    function VERSION() external view returns (string memory);
    function attest(DelegatedAttestationRequest memory delegatedRequest) external payable;
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
        ResolverUID resolverUID
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
        SchemaUID schemaUid,
        uint256 nonce
    )
        external
        view
        returns (bytes32 digest);
    function getAttestationDigest(
        AttestationRequestData memory attData,
        SchemaUID schemaUid,
        address attester
    )
        external
        view
        returns (bytes32 digest);
    function getDomainSeparator() external view returns (bytes32);
    function getModule(address moduleAddress) external returns (ModuleRecord memory);
    function getName() external view returns (string memory);
    function getNonce(address account) external view returns (uint256);
    function getResolver(ResolverUID uid) external view returns (ResolverRecord memory);
    function getRevocationDigest(
        RevocationRequestData memory revData,
        SchemaUID schemaUid,
        address revoker
    )
        external
        view
        returns (bytes32 digest);
    function getRevokeTypeHash() external pure returns (bytes32);
    function getSchema(SchemaUID uid) external view returns (SchemaRecord memory);
    function multiAttest(MultiDelegatedAttestationRequest[] memory multiDelegatedRequests)
        external
        payable;
    function multiAttest(MultiAttestationRequest[] memory multiRequests) external payable;
    function multiRevoke(MultiRevocationRequest[] memory multiRequests) external payable;
    function multiRevoke(MultiDelegatedRevocationRequest[] memory multiDelegatedRequests)
        external
        payable;
    function register(SchemaUID resolverUID, address moduleAddress, bytes memory data) external;
    function registerSchema(
        string memory schema,
        ISchemaValidator validator
    )
        external
        returns (SchemaUID uid);
    function registerResolver(IResolver resolver) external returns (ResolverUID);
    function revoke(RevocationRequest memory request) external payable;
    function setResolver(ResolverUID uid, IResolver resolver) external;
    function verify(address module, address[] memory attesters, uint256 threshold) external view;
    function verifyUnsafe(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view;
}
