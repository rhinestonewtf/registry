// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { AttestationRecord, AttestationRequest, RevocationRequest, SchemaUID } from "../DataTypes.sol";
import { AttestationManager } from "./AttestationManager.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * Abstract contract that implements the `IRegistry` interface
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
