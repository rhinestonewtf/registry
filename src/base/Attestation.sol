// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ReentrancyGuard } from "solmate/src/utils/ReentrancyGuard.sol";

import { EIP712Verifier } from "./EIP712Verifier.sol";
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
    uncheckedInc,
    InvalidSchema,
    _time
} from "../Common.sol";

import { AttestationDataRef, writeAttestationData, readAttestationData } from "../DataTypes.sol";
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

        // write attestations to registry storge
        (AttestationRecord memory attestation, uint256 value) = _writeAttestation({
            schemaUID: request.schemaUID,
            resolverUID: resolverUID,
            request: requestData,
            attester: msg.sender,
            timeNow: _time()
        });

        // trigger the resolver procedure
        _resolveAttestation({
            resolverUID: resolverUID,
            attestation: attestation,
            value: value,
            isRevocation: false,
            availableValue: msg.value,
            last: true
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

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == length - 1;
            }

            // Process the current batch of attestations.
            MultiAttestationRequest calldata multiRequest = multiRequests[i];
            uint256 usedValue = _multiAttest(
                multiRequest.schemaUID,
                moduleRecord.resolverUID,
                multiRequest.data,
                msg.sender,
                availableValue,
                last
            );

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
        RevocationRequestData[] memory requests = new RevocationRequestData[](
            1
        );
        requests[0] = request.data;

        ModuleRecord memory moduleRecord = _getModule({ moduleAddress: request.data.subject });

        AttestationRecord memory attestation =
            _revoke({ schemaUID: request.schemaUID, request: request.data, revoker: msg.sender });

        _resolveAttestation({
            resolverUID: moduleRecord.resolverUID,
            attestation: attestation,
            value: 0,
            isRevocation: true,
            availableValue: msg.value,
            last: true
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
        for (uint256 i; i < requestsLength; i = uncheckedInc(i)) {
            // The last batch is handled slightly differently: if the total available ETH wasn't spent in full and there
            // is a remainder - it will be refunded back to the attester (something that we can only verify during the
            // last and final batch).
            bool last;
            unchecked {
                last = i == requestsLength - 1;
            }

            MultiRevocationRequest calldata multiRequest = multiRequests[i];

            // Ensure to deduct the ETH that was forwarded to the resolver during the processing of this batch.
            availableValue -= _multiRevoke({
                schemaUID: multiRequest.schemaUID,
                resolverUID: moduleRecord.resolverUID,
                data: multiRequest.data,
                revoker: msg.sender,
                availableValue: availableValue,
                last: last
            });
        }
    }

    /**
     * @dev Attests to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema to attest to.
     * @param resolverUID The unique identifier of the resolver.
     * @param data The attestation data.
     * @param attester The attester's address.
     * @param availableValue Amount of ETH available for the operation.
     * @param last Indicates if this is the last batch.
     *
     * @return usedValue Amount of ETH used.
     */
    function _multiAttest(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData[] calldata data,
        address attester,
        uint256 availableValue,
        bool last
    )
        internal
        returns (uint256 usedValue)
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema(schemaUID);
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();
        // validate Schema
        ISchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (address(validator) != ZERO_ADDRESS) {
            // revert if ISchemaValidator returns false
            if (!schema.validator.validateSchema(data)) {
                revert InvalidAttestation();
            }
        }

        // caching length
        uint256 length = data.length;
        // caching current time as it will be used in the for loop
        uint48 timeNow = _time();

        // for loop will run and save the return values in these two arrays
        AttestationRecord[] memory attestations = new AttestationRecord[](
            length
        );

        // msg.values used for resolver
        uint256[] memory values = new uint256[](length);

        // write every attesatation provided to registry's storage
        for (uint256 i; i < length; i = uncheckedInc(i)) {
            (attestations[i], values[i]) = _writeAttestation({
                schemaUID: schemaUID,
                resolverUID: resolverUID,
                request: data[i],
                attester: attester,
                timeNow: timeNow
            });
        }

        // trigger the resolver procedure
        usedValue =
            _resolveAttestations(resolverUID, attestations, values, false, availableValue, last);
    }

    /**
     * Writes an attestation record to storage and emits an event.
     *
     * @dev the bytes metadata provided in the AttestationRequestData
     * is writted to the EVM with SSTORE2 to allow for large attestations without spending a lot of gas
     *
     * @param schemaUID The unique identifier of the schema being attested to.
     * @param resolverUID The unique identifier of the resolver for the module.
     * @param request The data for the attestation request.
     * @param attester The address of the entity making the attestation.
     * @param timeNow The current timestamp.
     *
     * @return attestation The written attestation record.
     * @return value The value associated with the attestation request.
     */
    function _writeAttestation(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        AttestationRequestData calldata request,
        address attester,
        uint48 timeNow
    )
        internal
        returns (AttestationRecord memory attestation, uint256 value)
    {
        // Ensure that either no expiration time was set or that it was set in the future.
        if (request.expirationTime != ZERO_TIMESTAMP && request.expirationTime <= timeNow) {
            revert InvalidExpirationTime();
        }
        // caching module address. gas bad
        address module = request.subject;
        ModuleRecord storage moduleRecord = _getModule({ moduleAddress: module });

        // Ensure that attestation is for module that was registered.
        if (moduleRecord.implementation == ZERO_ADDRESS) {
            revert InvalidAttestation();
        }

        // Ensure that attestation for a module is using the modules resolver
        if (moduleRecord.resolverUID != resolverUID) {
            revert InvalidAttestation();
        }

        // get salt used for SSTORE2 to avoid collisions during CREATE2
        bytes32 attestationSalt = AttestationLib.attestationSalt(attester, module);
        AttestationDataRef sstore2Pointer =
            writeAttestationData({ attestationData: request.data, salt: attestationSalt });

        // write attestationdata with SSTORE2 to EVM, and prepare return value
        attestation = AttestationRecord({
            schemaUID: schemaUID,
            subject: module,
            attester: attester,
            time: timeNow,
            expirationTime: request.expirationTime,
            revocationTime: uint48(ZERO_TIMESTAMP),
            dataPointer: sstore2Pointer
        });

        value = request.value;

        // SSTORE attestation on registry storage
        _moduleToAttesterToAttestations[module][attester] = attestation;
        emit Attested(module, attester, schemaUID, sstore2Pointer);
    }

    function _revoke(
        SchemaUID schemaUID,
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

        // Ensure that a wrong schema ID wasn't passed by accident.
        if (attestation.schemaUID != schemaUID) {
            revert InvalidSchema();
        }

        // Allow only original attesters to revoke their attestations.
        if (attestation.attester != revoker) {
            revert AccessDenied();
        }

        // Ensure that we aren't trying to revoke the same attestation twice.
        if (attestation.revocationTime != 0) {
            revert AlreadyRevoked();
        }

        attestation.revocationTime = _time();
        emit Revoked(attestation.subject, revoker, attestation.schemaUID);
        return attestation;
    }

    /**
     * @dev Revokes an existing attestation to a specific schema.
     *
     * @param schemaUID The unique identifier of the schema that was used to attest.
     * @param data The arguments of the revocation requests.
     * @param revoker The revoking account.
     * @param availableValue The total available ETH amount that can be sent to the resolver.
     * @param last Whether this is the last attestations/revocations set.
     *
     * @return Returns the total sent ETH amount.
     */
    function _multiRevoke(
        SchemaUID schemaUID,
        ResolverUID resolverUID,
        RevocationRequestData[] memory data,
        address revoker,
        uint256 availableValue,
        bool last
    )
        internal
        returns (uint256)
    {
        // only run this function if the selected schemaUID exists
        SchemaRecord storage schema = _getSchema(schemaUID);
        if (schema.registeredAt == ZERO_TIMESTAMP) revert InvalidSchema();

        // caching length
        uint256 length = data.length;
        AttestationRecord[] memory attestations = new AttestationRecord[](
            length
        );
        uint256[] memory values = new uint256[](length);

        for (uint256 i; i < length; i = uncheckedInc(i)) {
            RevocationRequestData memory request = data[i];

            _moduleToAttesterToAttestations[request.subject][request.attester];

            attestations[i] = _revoke({ schemaUID: schemaUID, request: request, revoker: revoker });
            values[i] = request.value;
        }

        return _resolveAttestations({
            resolverUID: resolverUID,
            attestations: attestations,
            values: values,
            isRevocation: true,
            availableValue: availableValue,
            last: last
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
