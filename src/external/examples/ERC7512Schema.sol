// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { IExternalSchemaValidator } from "../IExternalSchemaValidator.sol";
import { AttestationRecord, AttestationDataRef } from "../../DataTypes.sol";
import { AttestationLib } from "../../lib/AttestationLib.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";

interface ERC7512 {
    error ERC7512_InvalidModuleAddr();

    struct Auditor {
        string name;
        string uri;
        string[] authors;
    }

    struct Contract {
        bytes32 chainId;
        address deployment;
    }

    enum SignatureType {
        SECP256K1,
        ERC1271
    }

    struct Signature {
        SignatureType sigType;
        address signer;
        bytes data;
    }

    struct AuditSummary {
        Auditor auditor;
        uint256 issuedAt;
        uint256[] ercs;
        Contract auditedContract;
        bytes32 auditHash;
        string auditUri;
        uint256 signedAt;
        Signature auditorSignature;
    }
}

contract ERC7512SchemaValidator is IExternalSchemaValidator, ERC7512 {
    using AttestationLib for AttestationDataRef;

    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return (interfaceID == type(IExternalSchemaValidator).interfaceId);
    }

    function validateSchema(AttestationRecord calldata attestation)
        public
        view
        override
        returns (bool valid)
    {
        AuditSummary memory summary = abi.decode(attestation.dataPointer.sload2(), (AuditSummary));
        if (summary.auditedContract.deployment != attestation.moduleAddr) {
            return false;
        }
        if (summary.issuedAt > attestation.time) {
            return false;
        }

        valid = SignatureCheckerLib.isValidSignatureNow(
            summary.auditorSignature.signer, summary.auditHash, summary.auditorSignature.data
        );
    }

    function validateSchema(AttestationRecord[] calldata attestations)
        external
        view
        override
        returns (bool valid)
    {
        uint256 length = attestations.length;
        for (uint256 i = 0; i < length; i++) {
            if (!validateSchema(attestations[i])) {
                return false;
            }
        }
    }
}
