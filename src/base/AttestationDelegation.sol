// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IAttestation } from "../interface/IAttestation.sol";
import { Attestation } from "./Attestation.sol";
import {
    SignedAttestationRequest,
    MultiSignedAttestationRequest,
    SignedRevocationRequest,
    MultiSignedRevocationRequest,
    AttestationRequestData,
    ModuleRecord,
    ResolverUID,
    AttestationRecord,
    RevocationRequestData
} from "../DataTypes.sol";
import { InvalidLength } from "../Common.sol";

/**
 * @title AttestationDelegation
 * @dev This contract provides a signed approach to attesting and revoking attestations.
 *      The contract extends both IAttestation and Attestation.
 * @author rhinestone | zeroknots.eth, Konrad Kopp(@kopy-kat)
 */
abstract contract AttestationDelegation is IAttestation, Attestation {
    /*//////////////////////////////////////////////////////////////
                            ATTEST
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function attest(SignedAttestationRequest calldata signedRequest)
        external
        payable
        nonReentrant
    {
        // Get attestationRequestData calldata pointer
        AttestationRequestData calldata attestationRequestData = signedRequest.data;
        // check signature. this will revert  if signedRequest.attester != signer
        _requireValidAttestSignatureCalldata(signedRequest);
        // check if schema exists and is valid. This will revert if validtor returns false
        _requireSchemaCheck(signedRequest.schemaUID, attestationRequestData);

        // @audit could this be address(0), what happens if there is no module Record
        ModuleRecord storage moduleRecord =
            _getModule({ moduleAddress: attestationRequestData.moduleAddr });
        ResolverUID resolverUID = moduleRecord.resolverUID;

        // store attestation record
        (AttestationRecord memory attestationRecord, uint256 value) = _writeAttestation({
            schemaUID: signedRequest.schemaUID,
            attestationRequestData: attestationRequestData,
            attester: signedRequest.attester
        });

        // if a external resolver is configured for the resolver UID,
        // this will call the external resolver contract to validate the attestationrequest
        // should the external resolver return false, this will revert
        _requireExternalResolveAttestation({
            resolverUID: resolverUID,
            attestationRecord: attestationRecord,
            value: value,
            isRevocation: false,
            availableValue: msg.value,
            isLastAttestation: true
        });
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiAttest(MultiSignedAttestationRequest[] calldata multiSignedRequests)
        external
        payable
        nonReentrant
    {
        // check if schema exists and is valid. This will revert if validtor returns false
        _requireSchemaCheck({ schemaUID: multiSignedRequests.schemaUID, requestDatas: multiSignedRequests.data });
        uint256 length = multiSignedRequests.length;

        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiSignedRequests[0].data[0].moduleAddr });
        // TODO:
        // I think it would be much better to move this into the for loop so we can iterate over the requests.
        // Its possible that the MultiAttestationRequests is attesting different modules,
        // that thus have different resolvers gas bad

        for (uint256 i; i < length; ++i) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiSignedAttestationRequest calldata multiSignedRequest = multiSignedRequests[i];
            AttestationRequestData[] calldata attestationRequestDatas = multiSignedRequest.data;
            uint256 dataLength = attestationRequestDatas.length;

            // Ensure that no inputs are missing.
            if (dataLength != multiSignedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify signatures. Note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; ++j) {
                _requireValidAttestSignature(
                    SignedAttestationRequest({
                        schemaUID: multiSignedRequest.schemaUID,
                        data: attestationRequestDatas[j],
                        signature: multiSignedRequest.signatures[j],
                        attester: multiSignedRequest.attester
                    })
                );
            }

            // Process the current batch of attestations.
            uint256 usedValue = _multiAttest({
                schemaUID: multiSignedRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                attestationRequestDatas: attestationRequestDatas,
                attester: multiSignedRequest.attester,
                availableValue: availableValue,
                isLastAttestation: last
            });

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= usedValue;
        }
    }

    /*//////////////////////////////////////////////////////////////
                              REVOKE
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function revoke(SignedRevocationRequest calldata request) external payable nonReentrant {
        _verifyRevoke(request);

        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = request.data;

        ModuleRecord memory moduleRecord = _getModule({ moduleAddress: request.data.moduleAddr });

        _multiRevoke({
            schemaUID: request.schemaUID,
            resolverUID: moduleRecord.resolverUID,
            revocationRequestDatas: data,
            revoker: request.revoker,
            availableValue: msg.value,
            isLastRevocation: true
        });
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiRevoke(MultiSignedRevocationRequest[] calldata multiSignedRequests)
        external
        payable
        nonReentrant
    {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;
        uint256 length = multiSignedRequests.length;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiSignedRequests[0].data[0].moduleAddr });

        for (uint256 i; i < length; ++i) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiSignedRevocationRequest memory multiSignedRequest = multiSignedRequests[i];
            RevocationRequestData[] memory revocationRequestDatas = multiSignedRequest.data;
            uint256 dataLength = revocationRequestDatas.length;

            // Ensure that no inputs are missing.
            if (dataLength == 0 || dataLength != multiSignedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; ++j) {
                _verifyRevoke(
                    SignedRevocationRequest({
                        schemaUID: multiSignedRequest.schemaUID,
                        data: revocationRequestDatas[j],
                        signature: multiSignedRequest.signatures[j],
                        revoker: multiSignedRequest.revoker
                    })
                );
            }

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _multiRevoke({
                schemaUID: multiSignedRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                revocationRequestDatas: revocationRequestDatas,
                revoker: multiSignedRequest.revoker,
                availableValue: availableValue,
                isLastRevocation: last
            });
        }
    }
}
