// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { Attestation } from "./Attestation.sol";
import { AttestationRequest, RevocationRequest, SchemaUID } from "../DataTypes.sol";
import { AttestationLib } from "../lib/AttestationLib.sol";
import { EIP712 } from "solady/utils/EIP712.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * Implements similar functionality to Attestation.sol, but with the added feature of requiring a signature from the attester.
 *
 * ## Signed Attestations
 *
 * All Attestations leveraged within the Registry are designated as "signed/delegated".
 * Such Attestations empower an entity to sign an attestation while enabling another entity to
 * bear the transaction cost. With these attestations, the actual Attester and the one relaying the
 * Attestation can be separate entities, thus accommodating a variety of use cases.
 * This becomes particularly beneficial when:
 * Signatures may be provided as `ECDSA` or `ERC-1271`
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
contract SignedAttestation is IRegistry, Attestation, EIP712 {
    using AttestationLib for AttestationRequest;
    using AttestationLib for RevocationRequest;
    using AttestationLib for AttestationRequest[];
    using AttestationLib for RevocationRequest[];

    mapping(address attester => uint256 nonce) public attesterNonce;

    /**
     * @inheritdoc IRegistry
     */
    function attest(SchemaUID schemaUID, address attester, AttestationRequest calldata request, bytes calldata signature) external {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(request.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _attest({ attester: attester, schemaUID: schemaUID, request: request });
    }

    /**
     * @inheritdoc IRegistry
     */
    function attest(SchemaUID schemaUID, address attester, AttestationRequest[] calldata requests, bytes calldata signature) external {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(requests.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _attest({ attester: attester, schemaUID: schemaUID, requests: requests });
    }

    /**
     * @inheritdoc IRegistry
     */
    function revoke(address attester, RevocationRequest calldata request, bytes calldata signature) external {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(request.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _revoke({ attester: attester, request: request });
    }

    /**
     * @inheritdoc IRegistry
     */
    function revoke(address attester, RevocationRequest[] calldata requests, bytes calldata signature) external {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(requests.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _revoke({ attester: attester, requests: requests });
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  EIP712 Digest Helpers                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * override thats used by Solady's EIP712 cache (constructor)
     */
    function _domainNameAndVersion() internal view virtual override returns (string memory name, string memory version) {
        name = "RhinestoneRegistry";
        version = "v1.0";
    }

    function getDigest(AttestationRequest calldata request, address attester) external view returns (bytes32 digest) {
        digest = _hashTypedData(request.hash(attesterNonce[attester] + 1));
    }

    function getDigest(AttestationRequest[] calldata requests, address attester) external view returns (bytes32 digest) {
        digest = _hashTypedData(requests.hash(attesterNonce[attester] + 1));
    }

    function getDigest(RevocationRequest calldata request, address attester) external view returns (bytes32 digest) {
        digest = _hashTypedData(request.hash(attesterNonce[attester] + 1));
    }

    function getDigest(RevocationRequest[] calldata requests, address attester) external view returns (bytes32 digest) {
        digest = _hashTypedData(requests.hash(attesterNonce[attester] + 1));
    }
}
