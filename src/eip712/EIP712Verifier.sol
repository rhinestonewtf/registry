// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";

import "forge-std/console2.sol";

// prettier-ignore
import {
    AttestationRequest,
    AttestationRequestData,
    DelegatedAttestationRequest,
    DelegatedRevocationRequest,
    RevocationRequest,
    RevocationRequestData
} from "../interface/IRSAttestation.sol";

import { EIP712Signature, InvalidSignature } from "../Common.sol";

/**
 * @title EIP712 typed signatures verifier for EAS delegated attestations.
 */
abstract contract EIP712Verifier is EIP712 {
    // The hash of the data type used to relay calls to the attest function. It's the value of
    // keccak256("Attest(bytes32 schema,address recipient,uint64 expirationTime,bool revocable,bytes32 refUID,bytes data,uint256 nonce)").
    bytes32 private constant ATTEST_TYPEHASH =
        0xdbfdf8dc2b135c26253e00d5b6cbe6f20457e003fd526d97cea183883570de61;

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    // keccak256("Revoke(bytes32 schema,bytes32 uid,uint256 nonce)").
    bytes32 private constant REVOKE_TYPEHASH =
        0xa98d02348410c9c76735e0d0bb1396f4015ac2bb9615f9c2611d19d7a8a99650;

    bytes4 private constant ERC1271_RETURN_VALID_SIGNATURE = 0x20c13b0b;

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
        bytes32 schemaUid,
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
        bytes32 schemaUid,
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
                    schemaUid,
                    data.recipient,
                    data.expirationTime,
                    data.revocable,
                    data.refUID,
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
        EIP712Signature memory signature = request.signature;

        uint256 nonce;
        unchecked {
            nonce = ++_nonces[request.attester];
        }

        bytes32 digest = _attestationDigest(data, request.schema, nonce);
        _verifySignature(digest, signature, request.attester);
    }

    function getRevocationDigest(
        RevocationRequestData memory revData,
        bytes32 schemaUid,
        address revoker
    )
        public
        view
        returns (bytes32 digest)
    {
        uint256 nonce = getNonce(revoker);
        digest = _revocationDigest(schemaUid, revData.uid, nonce);
    }

    function _revocationDigest(
        bytes32 schemaUid,
        bytes32 revocationId,
        uint256 nonce
    )
        private
        view
        returns (bytes32 digest)
    {
        digest =
            _hashTypedDataV4(keccak256(abi.encode(REVOKE_TYPEHASH, schemaUid, revocationId, nonce)));
    }

    /**
     * @dev Verifies delegated revocation request.
     *
     * @param request The arguments of the delegated revocation request.
     */
    function _verifyRevoke(DelegatedRevocationRequest memory request) internal {
        RevocationRequestData memory data = request.data;
        EIP712Signature memory signature = request.signature;

        uint256 nonce;
        unchecked {
            nonce = _nonces[request.revoker]++;
        }

        // bytes32 digest = _hashTypedDataV4(
        //     keccak256(abi.encode(REVOKE_TYPEHASH, request.schema, data.uid, nonce))
        // );
        bytes32 digest = _revocationDigest(request.schema, data.uid, nonce);
        _verifySignature(digest, signature, request.revoker);
    }

    function _verifySignature(
        bytes32 digest,
        EIP712Signature memory signature,
        address signer
    )
        internal
        view
    {
        // check if signer is EOA or contract
        if (_isContract(signer)) {
            // check if contract implements EIP-1271
            bytes4 magicValue = IERC1271(signer).isValidSignature(digest, abi.encode(signature));
            if (magicValue != ERC1271_RETURN_VALID_SIGNATURE) {
                revert InvalidSignature();
            }
        } else {
            if (ECDSA.recover(digest, signature.v, signature.r, signature.s) != signer) {
                revert InvalidSignature();
            }
        }
    }

    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
