// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRequest, RevocationRequest, AttestationDataRef } from "../DataTypes.sol";
import { SSTORE2 } from "solady/utils/SSTORE2.sol";

library AttestationLib {
    // The hash of the data type used to relay calls to the attest function. It's the value of
    bytes32 internal constant ATTEST_REQUEST_TYPEHASH =
        keccak256("AttestationRequest(address moduleAddress,uint48 expirationTime,bytes data,uint256[] moduleTypes)");
    // solhint-disable max-line-length
    bytes32 internal constant ATTEST_TYPEHASH = keccak256(
        "SignedAttestationRequest(AttestationRequest request,uint256 nonce)AttestationRequest(address moduleAddress,uint48 expirationTime,bytes data,uint256[] moduleTypes)"
    );
    // solhint-disable max-line-length
    bytes32 internal constant ATTEST_ARRAY_TYPEHASH = keccak256(
        "SignedAttestationRequests(AttestationRequest[] requests,uint256 nonce)AttestationRequest(address moduleAddress,uint48 expirationTime,bytes data,uint256[] moduleTypes)"
    );

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    bytes32 internal constant REVOKE_REQUEST_TYPEHASH = keccak256("RevocationRequest(address moduleAddress)");
    bytes32 internal constant REVOKE_TYPEHASH =
        keccak256("SignedRevocationRequest(RevocationRequest request,uint256 nonce)RevocationRequest(address moduleAddress)");
    bytes32 internal constant REVOKE_ARRAY_TYPEHASH =
        keccak256("SignedRevocationRequests(RevocationRequest[] requests,uint256 nonce)RevocationRequest(address moduleAddress)");

    /**
     * Helper function to SSTORE2 read an attestation
     * @param dataPointer the pointer to the attestation data
     * @return data attestation data
     */
    function sload2(AttestationDataRef dataPointer) internal view returns (bytes memory data) {
        data = SSTORE2.read(AttestationDataRef.unwrap(dataPointer));
    }

    /**
     * Helper function to SSTORE2 write an attestation
     * @param request the attestation request
     * @param salt the salt to use for the deterministic address generation
     * @return dataPointer the pointer to the attestation data
     */
    function sstore2(AttestationRequest calldata request, bytes32 salt) internal returns (AttestationDataRef dataPointer) {
        /**
         * @dev We are using CREATE2 to deterministically generate the address of the attestation data.
         * Checking if an attestation pointer already exists, would cost more GAS in the average case.
         */
        dataPointer = AttestationDataRef.wrap(SSTORE2.writeDeterministic(request.data, salt));
    }

    /**
     * Create salt for SSTORE2.
     * The salt is constructed out of:
     *   - attester address
     *   - module address
     *   - current timestamp
     *   - chain id
     * @param attester the attester address
     * @param module the module address
     * @return salt the salt
     */
    function sstore2Salt(address attester, address module) internal view returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(attester, module, block.timestamp, block.chainid));
    }

    /**
     * generate hash for EIP712 for one attestation request
     * @param request attestation request
     * @param nonce the nonce for attestation request
     * @return _hash the hash
     */
    function hash(AttestationRequest calldata request, uint256 nonce) internal pure returns (bytes32 _hash) {
        _hash = keccak256(
            abi.encode(
                ATTEST_TYPEHASH,
                keccak256(
                    abi.encode(
                        ATTEST_REQUEST_TYPEHASH,
                        request.moduleAddress,
                        request.expirationTime,
                        keccak256(request.data),
                        keccak256(abi.encodePacked(request.moduleTypes))
                    )
                ),
                nonce
            )
        );
    }

    /**
     * generate hash for EIP712 for multiple attestation requests
     * @param requests attestation request
     * @param nonce the nonce for attestation request
     * @return _hash the hash
     */
    function hash(AttestationRequest[] calldata requests, uint256 nonce) internal pure returns (bytes32 _hash) {
        bytes memory concatinatedAttestations;

        uint256 length = requests.length;
        for (uint256 i; i < length; i++) {
            concatinatedAttestations = abi.encodePacked(
                concatinatedAttestations, // concat previous
                keccak256(
                    abi.encode(
                        ATTEST_REQUEST_TYPEHASH,
                        requests[i].moduleAddress,
                        requests[i].expirationTime,
                        keccak256(requests[i].data),
                        keccak256(abi.encodePacked(requests[i].moduleTypes))
                    )
                )
            );
        }

        _hash = keccak256(abi.encode(ATTEST_ARRAY_TYPEHASH, keccak256(concatinatedAttestations), nonce));
    }

    /**
     * generate hash for EIP712 for one revocation request
     * @param request attestation request
     * @param nonce the nonce for attestation request
     * @return _hash the hash
     */
    function hash(RevocationRequest calldata request, uint256 nonce) internal pure returns (bytes32 _hash) {
        _hash = keccak256(abi.encode(REVOKE_TYPEHASH, keccak256(abi.encode(REVOKE_REQUEST_TYPEHASH, request.moduleAddress)), nonce));
    }

    /**
     * generate hash for EIP712 for multiple revocation requests
     * @param requests attestation request
     * @param nonce the nonce for attestation request
     * @return _hash the hash
     */
    function hash(RevocationRequest[] calldata requests, uint256 nonce) internal pure returns (bytes32 _hash) {
        bytes memory concatinatedAttestations;

        uint256 length = requests.length;
        for (uint256 i; i < length; i++) {
            concatinatedAttestations = abi.encodePacked(
                concatinatedAttestations, // concat previous
                keccak256(abi.encode(REVOKE_REQUEST_TYPEHASH, requests[i].moduleAddress))
            );
        }

        _hash = keccak256(abi.encode(REVOKE_ARRAY_TYPEHASH, keccak256(concatinatedAttestations), nonce));
    }
}
