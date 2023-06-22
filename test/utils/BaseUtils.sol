// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";

// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

import "../../src/RhinestoneRegistry.sol";

address constant VM_ADDR = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
bytes12 constant ADDR_MASK = 0xffffffffffffffffffffffff;

function getAddr(uint256 pk) pure returns (address) {
    return Vm(VM_ADDR).addr(pk);
}

struct RegistryInstance {
    RhinestoneRegistry registry;
    string name;
    Yaho yaho;
    Yaru yaru;
}

library RegistryTestLib {
    function mockAttestation(
        RegistryInstance memory instance,
        bytes32 schemaId,
        uint256 attesterKey,
        address moduleAddr
    )
        public
        returns (bytes32 attestationUid)
    {
        AttestationRequestData memory attData = AttestationRequestData({
            recipient: moduleAddr,
            expirationTime: uint48(0),
            revocable: true,
            propagateable: true,
            refUID: "",
            data: abi.encode(true),
            value: 0
        });
        return newAttestation(instance, schemaId, attesterKey, attData);
    }

    function newAttestation(
        RegistryInstance memory instance,
        bytes32 schemaId,
        uint256 attesterKey,
        AttestationRequestData memory attData
    )
        public
        returns (bytes32 attestationUid)
    {
        EIP712Signature memory signature = signAttestation(instance, schemaId, attesterKey, attData);
        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schema: schemaId,
            data: attData,
            signature: signature,
            attester: getAddr(attesterKey)
        });

        attestationUid = instance.registry.attest(req);
    }

    function signAttestation(
        RegistryInstance memory instance,
        bytes32 schemaId,
        uint256 attesterPk,
        AttestationRequestData memory attData
    )
        internal
        returns (EIP712Signature memory sig)
    {
        bytes32 digest = instance.registry.getAttestationDigest({
            attData: attData,
            schemaUid: schemaId,
            attester: getAddr(attesterPk)
        });

        (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(attesterPk, digest);
        sig = EIP712Signature({ v: v, r: r, s: s });
    }

    function revokeAttestation(
        RegistryInstance memory instance,
        bytes32 attestationUid,
        bytes32 schemaId,
        uint256 attesterPk
    )
        public
    {
        RevocationRequestData memory revoke =
            RevocationRequestData({ uid: attestationUid, value: 0 });

        bytes32 digest =
            instance.registry.getRevocationDigest(revoke, schemaId, getAddr(attesterPk));

        (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(attesterPk, digest);
        EIP712Signature memory signature = EIP712Signature({ v: v, r: r, s: s });

        DelegatedRevocationRequest memory req = DelegatedRevocationRequest({
            schema: schemaId,
            data: revoke,
            signature: signature,
            revoker: getAddr(attesterPk)
        });
        instance.registry.revoke(req);
    }

    function registerSchema(
        RegistryInstance memory instance,
        string memory abiString,
        ISchemaResolver resolver,
        bool revocable
    )
        internal
        returns (bytes32 schemaId)
    {
        return instance.registry.registerSchema(abiString, resolver, revocable);
    }

    function deployAndRegister(
        RegistryInstance memory instance,
        bytes32 schemaId,
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
            data: "",
            schemaId: schemaId
        });
    }
}

contract RegistryTestTools {
    using RegistryTestLib for RegistryInstance;

    function _setupInstance(string memory name) internal returns (RegistryInstance memory) {
        RegistryInstance memory instance;
        Yaru yaru = Yaru(address(0));
        Yaho yaho = Yaho(address(0));
        RhinestoneRegistry registry = new RhinestoneRegistry(
          yaho,
          yaru,
          address(0),
          name,
          "0.0.1"
        );

        instance = RegistryInstance(registry, name, yaho, yaru);
        return instance;
    }
}
