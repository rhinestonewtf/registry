// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IAttestation } from "../interface/IAttestation.sol";
import { Attestation } from "./Attestation.sol";
import {
    DelegatedAttestationRequest,
    MultiDelegatedAttestationRequest,
    DelegatedRevocationRequest,
    MultiDelegatedRevocationRequest,
    AttestationRequestData,
    ModuleRecord,
    ResolverUID,
    AttestationRecord,
    RevocationRequestData,
    SchemaRecord
} from "../DataTypes.sol";
import {
    ZERO_ADDRESS,
    AccessDenied,
    NotFound,
    ZERO_TIMESTAMP,
    InvalidLength,
    InvalidSchema,
    _time
} from "../Common.sol";

/**
 * @title AttestationDelegation
 * @dev This contract provides a delegated approach to attesting and revoking attestations.
 *      The contract extends both IAttestation and Attestation.
 * @author rhinestone | zeroknots.eth, Konrad Kopp(@kopy-kat)
 */
abstract contract AttestationDelegation is IAttestation, Attestation {
    /**
     * @dev Initializes the contract with a name and version for the attestation.
     */
    constructor() { }

    /*//////////////////////////////////////////////////////////////
                            ATTEST
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function attest(DelegatedAttestationRequest calldata delegatedRequest)
        external
        payable
        nonReentrant
    {
        _verifyAttest(delegatedRequest);

        AttestationRequestData calldata attestationRequestData = delegatedRequest.data;
        ModuleRecord storage moduleRecord =
            _getModule({ moduleAddress: delegatedRequest.data.subject });
        ResolverUID resolverUID = moduleRecord.resolverUID;

        verifyAttestationData(delegatedRequest.schemaUID, attestationRequestData);

        (AttestationRecord memory attestationRecord, uint256 value) = _writeAttestation({
            schemaUID: delegatedRequest.schemaUID,
            resolverUID: resolverUID,
            attestationRequestData: attestationRequestData,
            attester: delegatedRequest.attester
        });

        _resolveAttestation({
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
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable
        nonReentrant
    {
        uint256 length = multiDelegatedRequests.length;

        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiDelegatedRequests[0].data[0].subject });
        // I think it would be much better to move this into the for loop so we can iterate over the requests.
        // Its possible that the MultiAttestationRequests is attesting different modules, that thus have different resolvers
        // gas bad

        for (uint256 i; i < length; ++i) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedAttestationRequest calldata multiDelegatedRequest =
                multiDelegatedRequests[i];
            AttestationRequestData[] calldata attestationRequestDatas = multiDelegatedRequest.data;
            uint256 dataLength = attestationRequestDatas.length;

            // Ensure that no inputs are missing.
            if (dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify signatures. Note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; ++j) {
                _verifyAttest(
                    DelegatedAttestationRequest({
                        schemaUID: multiDelegatedRequest.schemaUID,
                        data: attestationRequestDatas[j],
                        signature: multiDelegatedRequest.signatures[j],
                        attester: multiDelegatedRequest.attester
                    })
                );
            }

            // Process the current batch of attestations.
            uint256 usedValue = _multiAttest({
                schemaUID: multiDelegatedRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                attestationRequestDatas: attestationRequestDatas,
                attester: multiDelegatedRequest.attester,
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
    function revoke(DelegatedRevocationRequest calldata request) external payable nonReentrant {
        _verifyRevoke(request);

        RevocationRequestData[] memory data = new RevocationRequestData[](1);
        data[0] = request.data;

        ModuleRecord memory moduleRecord = _getModule({ moduleAddress: request.data.subject });

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
    function multiRevoke(MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests)
        external
        payable
        nonReentrant
    {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;
        uint256 length = multiDelegatedRequests.length;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiDelegatedRequests[0].data[0].subject });

        for (uint256 i; i < length; ++i) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            MultiDelegatedRevocationRequest memory multiDelegatedRequest = multiDelegatedRequests[i];
            RevocationRequestData[] memory revocationRequestDatas = multiDelegatedRequest.data;
            uint256 dataLength = revocationRequestDatas.length;

            // Ensure that no inputs are missing.
            if (dataLength == 0 || dataLength != multiDelegatedRequest.signatures.length) {
                revert InvalidLength();
            }

            // Verify EIP712 signatures. Please note that the signatures are assumed to be signed with increasing nonces.
            for (uint256 j; j < dataLength; ++j) {
                _verifyRevoke(
                    DelegatedRevocationRequest({
                        schemaUID: multiDelegatedRequest.schemaUID,
                        data: revocationRequestDatas[j],
                        signature: multiDelegatedRequest.signatures[j],
                        revoker: multiDelegatedRequest.revoker
                    })
                );
            }

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _multiRevoke({
                schemaUID: multiDelegatedRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                revocationRequestDatas: revocationRequestDatas,
                revoker: multiDelegatedRequest.revoker,
                availableValue: availableValue,
                isLastRevocation: last
            });
        }
    }
}
