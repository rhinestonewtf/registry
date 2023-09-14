// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
/*//////////////////////////////////////////////////////////////
                  Import Hashi Core Components
//////////////////////////////////////////////////////////////*/

import "hashi/Hashi.sol";
import "hashi/GiriGiriBashi.sol";
// Hashi's contract to dispatch messages to L2
import "hashi/Yaho.sol";
// Hashi's contract to receive messages from L1
import "hashi/Yaru.sol";

/*//////////////////////////////////////////////////////////////
                      Hashi Bridge adapters
//////////////////////////////////////////////////////////////*/
import "hashi/adapters/AMB/AMBAdapter.sol";
import "hashi/adapters/AMB/IAMB.sol";
import "hashi/adapters/AMB/AMBMessageRelayer.sol";
import "hashi/adapters/AMB/test/MockAMB.sol";

import "../../src/Registry.sol";

import "forge-std/console2.sol";

address constant VM_ADDR = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;
bytes12 constant ADDR_MASK = 0xffffffffffffffffffffffff;

function getAddr(uint256 pk) pure returns (address) {
    return Vm(VM_ADDR).addr(pk);
}

struct RegistryInstance {
    Registry registry;
    string name;
    Yaho yaho;
    Yaru yaru;
}

struct HashiEnv {
    Hashi hashi;
    GiriGiriBashi giriGiriBashi;
    Yaho yaho;
    Yaru yaru;
    MockAMB amb;
    AMBMessageRelay ambMessageRelay;
    AMBAdapter ambAdapter;
}

library RegistryTestLib {
    function mockAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaUID,
        uint256 attesterKey,
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
        newAttestation(instance, schemaUID, attesterKey, attData);
    }

    function mockAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaUID,
        uint256 attesterKey,
        AttestationRequestData memory attData
    )
        public
    {
        newAttestation(instance, schemaUID, attesterKey, attData);
    }

    function newAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaUID,
        uint256 attesterKey,
        AttestationRequestData memory attData
    )
        public
    {
        EIP712Signature memory signature =
            signAttestation(instance, schemaUID, attesterKey, attData);
        DelegatedAttestationRequest memory req = DelegatedAttestationRequest({
            schemaUID: schemaUID,
            data: attData,
            signature: abi.encode(signature),
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
        returns (EIP712Signature memory sig)
    {
        uint256 nonce = instance.registry.getNonce(getAddr(attesterPk)) + 1;
        bytes32 digest = instance.registry.getAttestationDigest({
            attData: attData,
            schemaUid: schemaId,
            nonce: nonce
        });

        (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(attesterPk, digest);
        sig = EIP712Signature({ v: v, r: r, s: s });
    }

    function signAttestation(
        RegistryInstance memory instance,
        SchemaUID schemaId,
        uint256 attesterPk,
        AttestationRequestData[] memory attData
    )
        internal
        view
        returns (EIP712Signature[] memory sig)
    {
        sig = new EIP712Signature[](attData.length);

        uint256 nonce = instance.registry.getNonce(getAddr(attesterPk)) + 1;

        for (uint256 i = 0; i < attData.length; i++) {
            bytes32 digest = instance.registry.getAttestationDigest({
                attData: attData[i],
                schemaUid: schemaId,
                nonce: nonce + i
            });

            (uint8 v, bytes32 r, bytes32 s) = Vm(VM_ADDR).sign(attesterPk, digest);
            sig[i] = EIP712Signature({ v: v, r: r, s: s });
        }
    }

    function revokeAttestation(
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
        EIP712Signature memory signature = EIP712Signature({ v: v, r: r, s: s });

        DelegatedRevocationRequest memory req = DelegatedRevocationRequest({
            schemaUID: schemaId,
            data: revoke,
            signature: abi.encode(signature),
            revoker: getAddr(attesterPk)
        });
        instance.registry.revoke(req);
    }

    function registerSchemaAndResolver(
        RegistryInstance memory instance,
        string memory abiString,
        ISchemaValidator validator,
        ISchemaResolver resolver
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
        ISchemaResolver resolver
    )
        internal
        returns (ResolverUID resolverUID)
    {
        resolverUID = instance.registry.registerSchemaResolver(resolver);
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
            data: "",
            resolverUID: resolverUID
        });

        ModuleRecord memory moduleRecord = instance.registry.getModule(moduleAddr);
        require(moduleRecord.resolverUID == resolverUID, "resolverUID mismatch");
    }
}

contract RegistryTestTools {
    using RegistryTestLib for RegistryInstance;

    function _setupHashi(address hashiSigner) internal returns (HashiEnv memory hashiEnv) {
        Hashi hashi = new Hashi();
        GiriGiriBashi giriGiriBashi = new GiriGiriBashi(
            hashiSigner,
            address(hashi)
        );
        Yaho yaho = new Yaho();
        MockAMB amb = new MockAMB();
        Yaru yaru = new Yaru(
            IHashi(address(hashi)),
            address(yaho),
            block.chainid
        );
        AMBMessageRelay ambMessageRelay = new AMBMessageRelay(
            IAMB(address(amb)),
            yaho
        );
        AMBAdapter ambAdapter = new AMBAdapter(
            IAMB(address(amb)),
            address(ambMessageRelay),
            bytes32(block.chainid)
        );

        hashiEnv = HashiEnv({
            hashi: hashi,
            giriGiriBashi: giriGiriBashi,
            yaho: yaho,
            yaru: yaru,
            amb: amb,
            ambMessageRelay: ambMessageRelay,
            ambAdapter: ambAdapter
        });
    }

    function _setupInstance(
        string memory name,
        Yaho yaho,
        Yaru yaru,
        address l1Registry
    )
        internal
        returns (RegistryInstance memory)
    {
        RegistryInstance memory instance;

        Registry registry = new Registry(yaho, yaru, l1Registry, name, "0.0.1");

        instance = RegistryInstance(registry, name, yaho, yaru);
        return instance;
    }
}
