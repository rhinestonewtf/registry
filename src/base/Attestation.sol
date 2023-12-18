// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ReentrancyGuard } from "solmate/utils/ReentrancyGuard.sol";

import {
    IAttestation,
    AttestationRecord,
    AttestationRequest,
    MultiAttestationRequest,
    RevocationRequest,
    MultiRevocationRequest,
    AttestationLib,
    ResolverRecord,
    MultiDelegatedAttestationRequest
} from "../interface/IAttestation.sol";
import { SchemaUID, ResolverUID, SchemaRecord, ISchemaValidator } from "./Schema.sol";
import { ModuleRecord, AttestationRequestData, RevocationRequestData } from "./Module.sol";
import { ModuleDeploymentLib } from "../lib/ModuleDeploymentLib.sol";
import {
    ZERO_ADDRESS,
    AccessDenied,
    NotFound,
    ZERO_TIMESTAMP,
    InvalidLength,
    InvalidSchema,
    _time
} from "../Common.sol";

import { AttestationDataRef, writeAttestationData } from "../DataTypes.sol";
import { AttestationResolve } from "./AttestationResolve.sol";

/**
 * @title Attestation
 * @dev Manages attestations and revocations for modules.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp(@kopy-kat)
 */
abstract contract Attestation is IAttestation, AttestationResolve, ReentrancyGuard {
    using ModuleDeploymentLib for address;

    // Mapping of module addresses to attester addresses to their attestation records.
    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal
        _moduleToAttesterToAttestations;

    /**
     * @notice Constructs a new Attestation contract instance.
     */
    constructor() { }

    /*//////////////////////////////////////////////////////////////
                              ATTEST
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IAttestation
     */
    function attest(AttestationRequest calldata request) external payable nonReentrant {
        AttestationRequestData calldata requestData = request.data;

        ModuleRecord storage moduleRecord = _getModule({ moduleAddress: request.data.subject });
        ResolverUID resolverUID = moduleRecord.resolverUID;

        verifyAttestationData(request.schemaUID, requestData);

        // write attestations to registry storge
        (AttestationRecord memory attestationRecord, uint256 value) = _writeAttestation({
            schemaUID: request.schemaUID,
            resolverUID: resolverUID,
            attestationRequestData: requestData,
            attester: msg.sender
        });

        // trigger the resolver procedure
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
    function multiAttest(MultiAttestationRequest[] calldata multiRequests)
        external
        payable
        nonReentrant
    {
        uint256 length = multiRequests.length;
        uint256 availableValue = msg.value;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord storage moduleRecord =
            _getModule({ moduleAddress: multiRequests[0].data[0].subject });

        for (uint256 i; i < length; ++i) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            // Process the current batch of attestations.
            MultiAttestationRequest calldata multiRequest = multiRequests[i];
            uint256 usedValue = _multiAttest({
                schemaUID: multiRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                attestationRequestDatas: multiRequest.data,
                attester: msg.sender,
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
    function revoke(RevocationRequest calldata request) external payable nonReentrant {
        ModuleRecord memory moduleRecord = _getModule({ moduleAddress: request.data.subject });

        SchemaRecord storage schema = _getSchema({ schemaUID: request.schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();

        AttestationRecord memory attestationRecord =
            _revoke({ request: request.data, revoker: msg.sender });

        _resolveAttestation({
            resolverUID: moduleRecord.resolverUID,
            attestationRecord: attestationRecord,
            value: 0,
            isRevocation: true,
            availableValue: msg.value,
            isLastAttestation: true
        });
    }

    /**
     * @inheritdoc IAttestation
     */
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests)
        external
        payable
        nonReentrant
    {
        // We are keeping track of the total available ETH amount that can be sent to resolvers and will keep deducting
        // from it to verify that there isn't any attempt to send too much ETH to resolvers. Please note that unless
        // some ETH was stuck in the contract by accident (which shouldn't happen in normal conditions), it won't be
        // possible to send too much ETH anyway.
        uint256 availableValue = msg.value;

        // Batched Revocations can only be done for a single resolver. See IAttestation.sol
        ModuleRecord memory moduleRecord =
            _getModule({ moduleAddress: multiRequests[0].data[0].subject });
        uint256 requestsLength = multiRequests.length;

        // should cache length
        for (uint256 i; i < requestsLength; ++i) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool isLastRevocation;
            unchecked {
                isLastRevocation = i == requestsLength - 1;
            }

            MultiRevocationRequest calldata multiRequest = multiRequests[i];

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _multiRevoke({
                schemaUID: multiRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                revocationRequestDatas: multiRequest.data,
                revoker: msg.sender,
                availableValue: availableValue,
                isLastRevocation: isLastRevocation
            });
        }
    }

    /**
     * @dev Attests to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema to attest to.
     * @param resolverUID The unique identifier of the resolver.
     * @param attestationRequestDatas The attestation data.
     * @param attester The attester's address.
     * @param availableValue Amount of ETH available for the operation.
     * @param isLastAttestation Indicates if this is the last batch.
     *
     * @return usedValue Amount of ETH used.
     */
    function _multiAttest(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData[] calldata attestationRequestDatas,
        address attester,
        uint256 availableValue,
        bool isLastAttestation
    )
        internal
        returns (uint256 usedValue)
    {
        verifyAttestationData(schemaUID, attestationRequestDatas);

        // caching length
        uint256 length = attestationRequestDatas.length;
        // caching current time as it will be used in the for loop

        // for loop will run and save the return values in these two arrays
        AttestationRecord[] memory attestationRecords = new AttestationRecord[](
            length
        );

        // msg.values used for resolver
        uint256[] memory values = new uint256[](length);

        // write every attesatation provided to registry's storage
        for (uint256 i; i < length; ++i) {
            (attestationRecords[i], values[i]) = _writeAttestation({
                schemaUID: schemaUID,
                resolverUID: resolverUID,
                attestationRequestData: attestationRequestDatas[i],
                attester: attester
            });
        }

        // trigger the resolver procedure
        usedValue = _resolveAttestations({
            resolverUID: resolverUID,
            attestationRecords: attestationRecords,
            values: values,
            isRevocation: false,
            availableValue: availableValue,
            isLast: isLastAttestation
        });
    }

    function verifyAttestationData(
        SchemaUID schemaUID,
        AttestationRequestData calldata requestData
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema({ schemaUID: schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS) {
            // revert if ISchemaValidator returns false
            if (!schema.validator.validateSchema(requestData)) {
                revert InvalidAttestation();
            }
        }
    }

    function verifyAttestationData(
        SchemaUID schemaUID,
        AttestationRequestData[] calldata requestDatas
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema({ schemaUID: schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS) {
            // revert if ISchemaValidator returns false
            if (!schema.validator.validateSchema(requestDatas)) {
                revert InvalidAttestation();
            }
        }
    }

    /**
     * Writes an attestation record to storage and emits an event.
     *
     * @dev the bytes metadata provided in the AttestationRequestData
     * is writted to the EVM with SSTORE2 to allow for large attestations without spending a lot of gas
     *
     * @param schemaUID The unique identifier of the schema being attested to.
     * @param resolverUID The unique identifier of the resolver for the module.
     * @param attestationRequestData The data for the attestation request.
     * @param attester The address of the entity making the attestation.
     *
     * @return attestationRecord The written attestation record.
     * @return value The value associated with the attestation request.
     */
    function _writeAttestation(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData calldata attestationRequestData,
        address attester
    )
        internal
        returns (AttestationRecord memory attestationRecord, uint256 value)
    {
        uint48 timeNow = _time();
        // Ensure that either no expiration time was set or that it was set in the future.
        if (
            attestationRequestData.expirationTime != ZERO_TIMESTAMP
                && attestationRequestData.expirationTime <= timeNow
        ) {
            revert InvalidExpirationTime();
        }
        // caching module address. gas bad
        address module = attestationRequestData.subject;
        ModuleRecord storage moduleRecord = _getModule({ moduleAddress: module });

        // Ensure that attestation is for module that was registered.
        if (moduleRecord.implementation == ZERO_ADDRESS) {
            revert InvalidAttestation();
        }

        // salt = 0 so that attestation data can be reused
        bytes32 attestationSalt = bytes32(0);
        AttestationDataRef sstore2Pointer = writeAttestationData({
            attestationData: attestationRequestData.data,
            salt: attestationSalt,
            thisAddress: address(this)
        });

        // write attestationdata with SSTORE2 to EVM, and prepare return value
        attestationRecord = AttestationRecord({
            schemaUID: schemaUID,
            subject: module,
            attester: attester,
            time: timeNow,
            expirationTime: attestationRequestData.expirationTime,
            revocationTime: uint48(ZERO_TIMESTAMP),
            dataPointer: sstore2Pointer
        });

        value = attestationRequestData.value;

        // SSTORE attestation on registry storage
        _moduleToAttesterToAttestations[module][attester] = attestationRecord;
        emit Attested(module, attester, schemaUID, sstore2Pointer);
    }

    function _revoke(
        RevocationRequestData memory request,
        address revoker
    )
        internal
        returns (AttestationRecord memory)
    {
        AttestationRecord storage attestation =
            _moduleToAttesterToAttestations[request.subject][request.attester];

        // Ensure that we aren't attempting to revoke a non-existing attestation.
        if (AttestationDataRef.unwrap(attestation.dataPointer) == ZERO_ADDRESS) {
            revert NotFound();
        }

        // Allow only original attesters to revoke their attestations.
        if (attestation.attester != revoker) {
            revert AccessDenied();
        }

        // Ensure that we aren't trying to revoke the same attestation twice.
        if (attestation.revocationTime != ZERO_TIMESTAMP) {
            revert AlreadyRevoked();
        }

        attestation.revocationTime = _time();
        emit Revoked({
            subject: attestation.subject,
            revoker: revoker,
            schema: attestation.schemaUID
        });
        return attestation;
    }

    /**
     * @dev Revokes an existing attestation to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema that was used to attest.
     * @param revocationRequestDatas The arguments of the revocation requests.
     * @param revoker The revoking account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param isLastRevocation Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _multiRevoke(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        RevocationRequestData[] memory revocationRequestDatas,
        address revoker,
        uint256 availableValue,
        bool isLastRevocation
    )
        internal
        returns (uint256)
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema({ schemaUID: schemaUID });
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();

        // caching length
        uint256 length = revocationRequestDatas.length;
        AttestationRecord[] memory attestationRecords = new AttestationRecord[](
            length
        );
        uint256[] memory values = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            RevocationRequestData memory revocationRequests = revocationRequestDatas[i];

            attestationRecords[i] = _revoke({ request: revocationRequests, revoker: revoker });
            values[i] = revocationRequests.value;
        }

        return _resolveAttestations({
            resolverUID: resolverUID,
            attestationRecords: attestationRecords,
            values: values,
            isRevocation: true,
            availableValue: availableValue,
            isLast: isLastRevocation
        });
    }

    /**
     * @dev Returns the attestation record for a specific module and attester.
     *
     * @param module The module address.
     * @param attester The attester address.
     *
     * @return attestationRecord The attestation record.
     */
    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage)
    {
        return _moduleToAttesterToAttestations[module][attester];
    }
}
