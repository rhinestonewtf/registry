// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { Attestation } from "./Attestation.sol";
import { AttestationLib } from "../lib/AttestationLib.sol";

contract SignedAttestation is Attestation {
    using AttestationLib for AttestationRequestData;

    error InvalidSignature();

    mapping(address attester => uint256 nonce) public attesterNonce;

    function attest(
        SchemaUID schemaUID,
        AttestationRequestData calldata request,
        address attester,
        bytes calldata signature
    )
        external
        payable
    {
        // verify signature
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = request.digest(nonce, schemaUID);
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _attest(attester, schemaUID, request);
    }

    function attest(
        SchemaUID schemaUID,
        AttestationRequestData[] calldata requests,
        address attester,
        bytes[] calldata signature // TODO: should we maybe sign all requests at once?
    )
        external
        payable
    {
        // verify all signatures. Iterate nonces and digests
        uint256 nonce = attesterNonce[attester];
        uint256 length = requests.length;
        if (length != signature.length) revert InvalidSignature();
        for (uint256 i; i < length; i++) {
            bytes32 digest = requests[i].digest(nonce + i);
            bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature[i]);
            if (!valid) revert InvalidSignature();
        }
        // update nonce
        attesterNonce[attester] += length;

        _attest(attester, schemaUID, requests);
    }
}
