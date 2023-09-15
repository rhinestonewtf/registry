// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";

import { InvalidSignature } from "../Common.sol";
import "../DataTypes.sol";

/**
 * @title Singature Verifier. If provided signed is a contract, this function will fallback to ERC1271
 *
 * @author zeroknots.eth
 */
abstract contract EIP712Verifier is EIP712 {
    // The hash of the data type used to relay calls to the attest function. It's the value of
    bytes32 private constant ATTEST_TYPEHASH =
        keccak256("AttestationRequestData(address,uint48,uint256,bytes)");

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    bytes32 private constant REVOKE_TYPEHASH =
        keccak256("RevocationRequestData(address,address,uint256)");

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 private constant ERC1271_RETURN_VALID_SIGNATURE = 0x1626ba7e;

    // The user readable name of the signing domain.
    string private _name;

    // Replay protection nonces.
    mapping(address => uint256) private _nonces;

    /**
     * @dev Creates a new EIP712Verifier instance.
     *
     * @param version The current major version of the signing domain
     */
    constructor(string memory name, string memory version) EIP712(name, version) {
        _name = name;
    }

    /**
     * @dev Returns the domain separator used in the encoding of the signatures for attest, and revoke.
     */
    function getDomainSeparator() public view returns (bytes32) {
        return _domainSeparatorV4();
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
     * Returns the EIP712 name.
     */
    function getName() public view returns (string memory) {
        return _name;
    }

    function getAttestationDigest(
        AttestationRequestData memory attData,
        SchemaUID schemaUid,
        uint256 nonce
    )
        public
        view
        returns (bytes32 digest)
    {
        digest = _attestationDigest(attData, schemaUid, nonce);
    }

    function getAttestationDigest(
        AttestationRequestData memory attData,
        SchemaUID schemaUid,
        address attester
    )
        public
        view
        returns (bytes32 digest)
    {
        uint256 nonce = getNonce(attester) + 1;
        digest = _attestationDigest(attData, schemaUid, nonce);
    }

    function _attestationDigest(
        AttestationRequestData memory data,
        SchemaUID schemaUid,
        uint256 nonce
    )
        private
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ATTEST_TYPEHASH,
                    block.chainid,
                    schemaUid,
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

    function _newNonce(address account) private returns (uint256 nonce) {
        unchecked {
            nonce = ++_nonces[account];
        }
    }

    function getRevocationDigest(
        RevocationRequestData memory revData,
        SchemaUID schemaUid,
        address revoker
    )
        public
        view
        returns (bytes32 digest)
    {
        uint256 nonce = getNonce(revoker) + 1;
        digest = _revocationDigest(schemaUid, revData.subject, revData.attester, nonce);
    }

    function _revocationDigest(
        SchemaUID schemaUid,
        address subject,
        address attester,
        uint256 nonce
    )
        private
        view
        returns (bytes32 digest)
    {
        digest = _hashTypedDataV4(
            keccak256(
                abi.encode(REVOKE_TYPEHASH, block.chainid, schemaUid, subject, attester, nonce)
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

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
