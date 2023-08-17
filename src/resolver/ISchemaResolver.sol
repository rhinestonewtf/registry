// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AttestationRecord, ModuleRecord } from "../Common.sol";

/**
 * @title The interface of an optional schema resolver.
 */
interface ISchemaResolver {
    /**
     * @dev Returns whether the resolver supports ETH transfers.
     */
    function isPayable() external pure returns (bool);

    /**
     * @dev Processes an attestation and verifies whether it's valid.
     *
     * @param attestation The new attestation.
     *
     * @return Whether the attestation is valid.
     */
    function attest(AttestationRecord calldata attestation) external payable returns (bool);

    /**
     * @dev Processes a Module Registration
     *
     * @param module Module registration artefact
     *
     * @return Whether the registration is valid
     */
    function moduleRegistration(ModuleRecord calldata module) external payable returns (bool);

    /**
     * @dev Processes an Attestation Propagation
     *
     * @param attestation Attestation propagation artefact
     * @param sender Sender of the message
     * @param to Receiver of the message
     * @param toChainId Chain ID of the receiver
     * @param moduleOnL2 Module on L2
     *
     * @return Whether the  propagation is valid
     */
    function propagation(
        AttestationRecord calldata attestation,
        address sender,
        address to,
        uint256 toChainId,
        address moduleOnL2
    )
        external
        payable
        returns (bool);

    /**
     * @dev Processes multiple attestations and verifies whether they are valid.
     *
     * @param attestations The new attestations.
     * @param values Explicit ETH amounts which were sent with each attestation.
     *
     * @return Whether all the attestations are valid.
     */
    function multiAttest(
        AttestationRecord[] calldata attestations,
        uint256[] calldata values
    )
        external
        payable
        returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     *
     * @return Whether the attestation can be revoked.
     */
    function revoke(AttestationRecord calldata attestation) external payable returns (bool);

    /**
     * @dev Processes revocation of multiple attestation and verifies they can be revoked.
     *
     * @param attestations The existing attestations to be revoked.
     * @param values Explicit ETH amounts which were sent with each revocation.
     *
     * @return Whether the attestations can be revoked.
     */
    function multiRevoke(
        AttestationRecord[] calldata attestations,
        uint256[] calldata values
    )
        external
        payable
        returns (bool);
}
