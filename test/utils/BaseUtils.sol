// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";

import "../../src/Registry.sol";
import {
    AttestationRequestData,
    RevocationRequestData,
    DelegatedAttestationRequest,
    DelegatedRevocationRequest
} from "../../src/base/AttestationDelegation.sol";
import { ISchemaValidator, IResolver } from "../../src/interface/ISchema.sol";
import { AttestationRequest, RevocationRequest } from "../../src/DataTypes.sol";

import "forge-std/console2.sol";

address constant VM_ADDR = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
bytes12 constant ADDR_MASK = 0xffffffffffffffffffffffff;

function getAddr(uint256 pk) pure returns (address) {
    return Vm(VM_ADDR).addr(pk);
}

struct RegistryInstance {
    Registry registry;
    string name;
}

library RegistryTestLib {
    function mockAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaUID,
        address moduleAddr
    )
        public
    {
        AttestationRequestData memory attData = AttestationRequestData({
            subject: moduleAddr,
            expirationTime: uint48(0),
            data: abi.encode(true),
            value: 0
        });
        newAttestation(instance, schemaUID, attData);
    }

    function mockAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaUID,
        AttestationRequestData memory attData
    )
        public
    {
        newAttestation(instance, schemaUID, attData);
    }

    function newAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaUID,
        AttestationRequestData memory attData
    )
        public
    {
        AttestationRequest memory req = AttestationRequest({ schemaUID: schemaUID, data: attData });
        instance.registry.attest(req);
    }

    function newDelegatedAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaUID,
        uint256 attesterKey,
        AttestationRequestData memory attData
    )
        public
    {
        bytes memory signature = signAttestation(instance, schemaUID, attesterKey, attData);
        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schemaUID: schemaUID,
            data: attData,
            signature: signature,
            attester: getAddr(attesterKey)
        });
        instance.registry.attest(req);
    }

    function signAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaId,
        uint256 attesterPk,
        AttestationRequestData memory attData
    )
        internal
        view
        returns (bytes memory sig)
    {
        uint256 nonce = instance.registry.getNonce(getAddr(attesterPk)) + 1;
        bytes32 digest = instance.registry.getAttestationDigest({
            attData: attData,
            schemaUid: schemaId,
            nonce: nonce
        });

        (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(attesterPk, digest);
        sig = abi.encodePacked(r, s, v);
        require(
            SignatureCheckerLib.isValidSignatureNow(getAddr(attesterPk), digest, sig) == true,
            "Internal Error"
        );
    }

    function signAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaId,
        uint256 attesterPk,
        AttestationRequestData[] memory attData
    )
        internal
        view
        returns (bytes[] memory sig)
    {
        sig = new bytes[](attData.length);

        uint256 nonce = instance.registry.getNonce(getAddr(attesterPk)) + 1;

        for (uint256 i = 0; i < attData.length; i++) {
            bytes32 digest = instance.registry.getAttestationDigest({
                attData: attData[i],
                schemaUid: schemaId,
                nonce: nonce + i
            });

            (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(attesterPk, digest);
            sig[i] = abi.encodePacked(r, s, v);

            require(
                SignatureCheckerLib.isValidSignatureNow(getAddr(attesterPk), digest, sig[i]) == true,
                "Internal Error"
            );
        }
    }

    function revokeAttestation(
        RegistryInstance memory instance,
        address module,
        SchemaUID schemaId,
        address attester
    )
        public
    {
        RevocationRequestData memory revoke =
            RevocationRequestData({ subject: module, attester: attester, value: 0 });

        RevocationRequest memory req = RevocationRequest({ schemaUID: schemaId, data: revoke });
        instance.registry.revoke(req);
    }

    function delegatedRevokeAttestation(
        RegistryInstance memory instance,
        address module,
        SchemaUID schemaId,
        uint256 attesterPk
    )
        public
    {
        RevocationRequestData memory revoke =
            RevocationRequestData({ subject: module, attester: getAddr(attesterPk), value: 0 });

        bytes32 digest =
            instance.registry.getRevocationDigest(revoke, schemaId, getAddr(attesterPk));

        (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(attesterPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        DelegatedRevocationRequest memory req = DelegatedRevocationRequest({
            schemaUID: schemaId,
            data: revoke,
            signature: signature,
            revoker: getAddr(attesterPk)
        });
        instance.registry.revoke(req);
    }

    function registerSchemaAndResolver(
        RegistryInstance memory instance,
        string memory abiString,
        ISchemaValidator validator,
        IResolver resolver
    )
        internal
        returns (SchemaUID schemaId, ResolverUID resolverId)
    {
        schemaId = registerSchema(instance, abiString, validator);
        resolverId = registerResolver(instance, resolver);
    }

    function registerSchema(
        RegistryInstance memory instance,
        string memory abiString,
        ISchemaValidator validator
    )
        internal
        returns (SchemaUID schemaId)
    {
        return instance.registry.registerSchema(abiString, validator);
    }

    function registerResolver(
        RegistryInstance memory instance,
        IResolver resolver
    )
        internal
        returns (ResolverUID resolverUID)
    {
        resolverUID = instance.registry.registerResolver(resolver);
    }

    function deployAndRegister(
        RegistryInstance memory instance,
        ResolverUID resolverUID,
        bytes memory bytecode,
        bytes memory constructorArgs
    )
        internal
        returns (address moduleAddr)
    {
        moduleAddr = instance.registry.deploy({
            code: bytecode,
            deployParams: constructorArgs,
            salt: 0,
            metadata: "",
            resolverUID: resolverUID
        });

        ModuleRecord memory moduleRecord = instance.registry.getModule(moduleAddr);
        require(moduleRecord.resolverUID == resolverUID, "resolverUID mismatch");
    }
}

contract RegistryTestTools {
    using RegistryTestLib for RegistryInstance;

    function _setupInstance(
        string memory name,
        bytes32 salt
    )
        internal
        returns (RegistryInstance memory)
    {
        RegistryInstance memory instance;

        Registry registry = new Registry{salt: salt}();

        instance = RegistryInstance(registry, name);
        return instance;
    }
}
