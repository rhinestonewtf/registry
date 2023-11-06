// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { EIP712 } from "solady/src/utils/EIP712.sol";

import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";

import { InvalidSignature } from "../Common.sol";
import {
    AttestationRequestData,
    SchemaUID,
    DelegatedAttestationRequest,
    RevocationRequestData,
    DelegatedRevocationRequest
} from "../DataTypes.sol";

/**
 * @title Singature Verifier. If provided signed is a contract, this function will fallback to ERC1271
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract EIP712Verifier is EIP712 {
    // The hash of the data type used to relay calls to the attest function. It's the value of
    bytes32 private constant ATTEST_TYPEHASH =
        keccak256("AttestationRequestData(address,uint48,uint256,bytes)");

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    bytes32 private constant REVOKE_TYPEHASH =
        keccak256("RevocationRequestData(address,address,uint256)");

    // Replay protection nonces.
    mapping(address => uint256) private _nonces;

    /**
     * @dev Creates a new EIP712Verifier instance.
     */
    constructor() { }

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory name, string memory version)
    {
        name = "Registry";
        version = "0.2.1";
    }

    /**
     * @dev Returns the domain separator used in the encoding of the signatures for attest, and revoke.
     */
    function getDomainSeparator() public view returns (bytes32) {
        return _domainSeparator();
    }

    /**
     * @dev Returns the current nonce per-account.
     *
     * @param account The requested account.
     *
     * @return The current nonce.
     */
    function getNonce(address account) public view returns (uint256) {
        return _nonces[account];
    }

    /**
     * Returns the EIP712 type hash for the attest function.
     */
    function getAttestTypeHash() public pure returns (bytes32) {
        return ATTEST_TYPEHASH;
    }

    /**
     * Returns the EIP712 type hash for the revoke function.
     */
    function getRevokeTypeHash() public pure returns (bytes32) {
        return REVOKE_TYPEHASH;
    }

    /**
     * @dev Gets the attestation digest
     *
     * @param attData The data in the attestation request.
     * @param schemaUID The UID of the schema.
     * @param nonce The nonce of the attestation request.
     *
     * @return digest The attestation digest.
     */
    function getAttestationDigest(
        AttestationRequestData memory attData,
        SchemaUID schemaUID,
        uint256 nonce
    )
        public
        view
        returns (bytes32 digest)
    {
        digest = _attestationDigest(attData, schemaUID, nonce);
    }

    /**
     * @dev Gets the attestation digest
     *
     * @param attData The data in the attestation request.
     * @param schemaUID The UID of the schema.
     * @param attester The address of the attester.
     *
     * @return digest The attestation digest.
     */
    function getAttestationDigest(
        AttestationRequestData memory attData,
        SchemaUID schemaUID,
        address attester
    )
        public
        view
        returns (bytes32 digest)
    {
        uint256 nonce = getNonce(attester) + 1;
        digest = _attestationDigest(attData, schemaUID, nonce);
    }

    /**
     * @dev Gets the attestation digest
     *
     * @param data The data in the attestation request.
     * @param schemaUID The UID of the schema.
     * @param nonce  The nonce of the attestation request.
     *
     * @return digest The attestation digest.
     */
    function _attestationDigest(
        AttestationRequestData memory data,
        SchemaUID schemaUID,
        uint256 nonce
    )
        private
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(
            keccak256(
                abi.encode(
                    ATTEST_TYPEHASH,
                    block.chainid,
                    schemaUID,
                    data.subject,
                    data.expirationTime,
                    keccak256(data.data),
                    nonce
                )
            )
        );
    }

    /**
     * @dev Verifies delegated attestation request.
     *
     * @param request The arguments of the delegated attestation request.
     */
    function _verifyAttest(DelegatedAttestationRequest memory request) internal {
        AttestationRequestData memory data = request.data;

        uint256 nonce = _newNonce(request.attester);
        bytes32 digest = _attestationDigest(data, request.schemaUID, nonce);
        bool valid =
            SignatureCheckerLib.isValidSignatureNow(request.attester, digest, request.signature);
        if (!valid) revert InvalidSignature();
    }

    /**
     * @dev Gets a new sequential nonce
     *
     * @param account The requested account.
     *
     * @return nonce The new nonce.
     */
    function _newNonce(address account) private returns (uint256 nonce) {
        unchecked {
            nonce = ++_nonces[account];
        }
    }

    /**
     * @dev Gets the revocation digest
     * @param revData The data in the revocation request.
     * @param schemaUID The UID of the schema.
     * @param revoker  The address of the revoker.
     *
     * @return digest The revocation digest.
     */
    function getRevocationDigest(
        RevocationRequestData memory revData,
        SchemaUID schemaUID,
        address revoker
    )
        public
        view
        returns (bytes32 digest)
    {
        uint256 nonce = getNonce(revoker) + 1;
        digest = _revocationDigest(schemaUID, revData.subject, revData.attester, nonce);
    }

    /**
     * @dev Gets the revocation digest
     * @param revData The data in the revocation request.
     * @param schemaUID The UID of the schema.
     * @param nonce  The nonce of the attestation request.
     *
     * @return digest The revocation digest.
     */
    function getRevocationDigest(
        RevocationRequestData memory revData,
        SchemaUID schemaUID,
        uint256 nonce
    )
        public
        view
        returns (bytes32 digest)
    {
        digest = _revocationDigest(schemaUID, revData.subject, revData.attester, nonce);
    }

    /**
     * @dev Gets the revocation digest
     * @param schemaUID The UID of the schema.
     * @param subject The address of the subject.
     * @param nonce  The nonce of the attestation request.
     *
     * @return digest The revocation digest.
     */
    function _revocationDigest(
        SchemaUID schemaUID,
        address subject,
        address attester,
        uint256 nonce
    )
        private
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedData(
            keccak256(
                abi.encode(REVOKE_TYPEHASH, block.chainid, schemaUID, subject, attester, nonce)
            )
        );
    }

    /**
     * @dev Verifies delegated revocation request.
     *
     * @param request The arguments of the delegated revocation request.
     */
    function _verifyRevoke(DelegatedRevocationRequest memory request) internal {
        RevocationRequestData memory data = request.data;

        uint256 nonce = _newNonce(request.revoker);
        bytes32 digest = _revocationDigest(request.schemaUID, data.subject, data.attester, nonce);
        bool valid =
            SignatureCheckerLib.isValidSignatureNow(request.revoker, digest, request.signature);
        if (!valid) revert InvalidSignature();
    }
}
