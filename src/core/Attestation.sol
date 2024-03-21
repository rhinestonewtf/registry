// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRecord, AttestationRequest, RevocationRequest, SchemaUID } from "../DataTypes.sol";
import { AttestationManager } from "./AttestationManager.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 *  Abstract contract that implements the `IRegistry` interface
 *
 *  Attestations on the Registry represent statements about Modules.
 *  An Attestation is made using a particular Schema that is used to encode and decode the Attestation data.
 *  The most important usecase for Attestations is to make statements about the security of a Module.
 *
 * ## Attestation Lifecycle
 *
 *  When an Attester creates an Attestation, the Attestation data, structured according to the Schema provided
 *  by the Attester, is then added to the Registry. During the Attestation's lifecycle, the Registry can invoke
 *  hooks on the SchemaResolver during specific events like Attestation creation and revocation.
 *  This allows the SchemaResolver to ensure the integrity and correctness of the attestation throughout
 *  its lifecycle.
 *
 *  ### AttestationRequest
 *  data is `abi.encode()` according to a defined schema. The data is not stored in the storage of the Registry,
 *  but is rather stored with `SSTORE2` to save gas and a pointer to this data is stored on the Registry.
 *
 * ![Sequence Diagram](public/docs/attestationOnly.svg)
 *
 * ### Interactions with the SchemaValidator
 *
 * Attestation data can be validated with an external contract than may to `abi.decode()` and validate all or specific fields.
 *
 * ### Interaction with the IExternalResolver
 *
 * Upon an Attestation's revocation, the Registry calls hooks on the associated IResolver, allowing the IResolver to
 * update its internal state or
 * perform other necessary actions. This allows for extended business logic integrations.
 *
 * ### The Revocation Process
 *
 * In the event that an Attester decides to revoke an Attestation, they issue a revocation call to the Registry.
 *  Upon receiving this call, the registry updates the revocationTime field within the attestation record.
 *  This timestamp acts as a clear indication that the attestation has been revoked, and any trust or claims
 *  that stem from it should be reconsidered.
 *
 * It's important to note that apart from the revocationTime, the rest of the attestation's metadata and data
 *  remains unchanged.
 * Due to the nature of `SSTORE2`, all attestation data will remain onchain and thus preserves the history of
 *  attestations done.
 *
 * ### Editing Attestations
 *
 * Attestations can not be edited. Should attestation data change, the old attestation must be revoked and a new attestation issued.
 *
 *
 * - A service opts to cover its users' Attestation costs (taking care of gas expenses)
 * - An entity wishes to execute multiple Attestations but allows the recipient or a different party to
 *  handle the transaction fees for blockchain integration.
 * Allows `msg.sender` to make attestations / revocations directly
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract Attestation is IRegistry, AttestationManager {
    /**
     * @inheritdoc IRegistry
     */
    function attest(SchemaUID schemaUID, AttestationRequest calldata request) external {
        _attest(msg.sender, schemaUID, request);
    }

    /**
     * @inheritdoc IRegistry
     */
    function attest(SchemaUID schemaUID, AttestationRequest[] calldata requests) external {
        _attest(msg.sender, schemaUID, requests);
    }

    /**
     * @inheritdoc IRegistry
     */
    function revoke(RevocationRequest calldata request) external {
        _revoke(msg.sender, request);
    }

    /**
     * @inheritdoc IRegistry
     */
    function revoke(RevocationRequest[] calldata requests) external {
        _revoke(msg.sender, requests);
    }

    /**
     * @inheritdoc IRegistry
     */
    function findAttestation(address module, address attester) external view returns (AttestationRecord memory attestation) {
        attestation = $getAttestation(module, attester);
    }

    /**
     * @inheritdoc IRegistry
     */
    function findAttestations(
        address module,
        address[] calldata attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations)
    {
        uint256 length = attesters.length;
        attestations = new AttestationRecord[](length);
        for (uint256 i; i < length; i++) {
            attestations[i] = $getAttestation(module, attesters[i]);
        }
    }
}
