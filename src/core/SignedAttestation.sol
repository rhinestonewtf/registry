// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { Attestation } from "./Attestation.sol";
import { AttestationRequest, RevocationRequest, SchemaUID } from "../DataTypes.sol";
import { AttestationLib } from "../lib/AttestationLib.sol";
import { EIP712 } from "solady/utils/EIP712.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { IRegistry } from "../IRegistry.sol";

contract SignedAttestation is IRegistry, Attestation, EIP712 {
    using AttestationLib for AttestationRequest;
    using AttestationLib for RevocationRequest;
    using AttestationLib for AttestationRequest[];
    using AttestationLib for RevocationRequest[];

    mapping(address attester => uint256 nonce) public attesterNonce;

    /**
     * Attestation can be made on any SchemaUID.
     * @dev the registry, will forward your AttestationRequest.Data to the SchemaManager to
     * check if the schema exists.
     * @param schemaUID The SchemaUID of the schema to be attested.
     */
    function attest(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest calldata request,
        bytes calldata signature
    )
        external
    {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(request.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _attest({ attester: attester, schemaUID: schemaUID, request: request });
    }

    function attest(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest[] calldata requests,
        bytes calldata signature
    )
        external
    {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(requests.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _attest({ attester: attester, schemaUID: schemaUID, requests: requests });
    }

    function revoke(
        address attester,
        RevocationRequest calldata request,
        bytes calldata signature
    )
        external
    {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(request.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _revoke({ attester: attester, request: request });
    }

    function revoke(
        address attester,
        RevocationRequest[] calldata requests,
        bytes calldata signature
    )
        external
    {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(requests.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _revoke({ attester: attester, requests: requests });
    }

    function _domainNameAndVersion()
        internal
        view
        virtual
        override
        returns (string memory name, string memory version)
    {
        name = "RhinestoneRegistry";
        version = "v1.0";
    }

    function getDigest(
        AttestationRequest calldata request,
        address attester
    )
        external
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(request.hash(attesterNonce[attester] + 1));
    }

    function getDigest(
        AttestationRequest[] calldata requests,
        address attester
    )
        external
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(requests.hash(attesterNonce[attester] + 1));
    }

    function getDigest(
        RevocationRequest calldata request,
        address attester
    )
        external
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(request.hash(attesterNonce[attester] + 1));
    }

    function getDigest(
        RevocationRequest[] calldata requests,
        address attester
    )
        external
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(requests.hash(attesterNonce[attester] + 1));
    }
}
