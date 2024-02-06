// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseTest } from "./utils/BaseTest.t.sol";
import { AttestationResolve, ResolverUID, SchemaUID } from "../src/base/AttestationResolve.sol";
import {
    AttestationRequest,
    MultiAttestationRequest,
    DelegatedAttestationRequest,
    MultiDelegatedAttestationRequest,
    RevocationRequest,
    DelegatedRevocationRequest,
    MultiDelegatedRevocationRequest,
    MultiRevocationRequest,
    IAttestation
} from "../src/interface/IAttestation.sol";
import { ISchemaValidator } from "../src/interface/ISchema.sol";
import { IResolver } from "../src/external/IResolver.sol";
import { ResolverBase } from "../src/external/ResolverBase.sol";
import {
    AttestationRecord,
    AttestationDataRef,
    MultiAttestationRequest,
    MultiDelegatedAttestationRequest,
    MultiRevocationRequest,
    DelegatedRevocationRequest,
    MultiDelegatedRevocationRequest,
    SchemaRecord,
    ResolverRecord,
    ModuleRecord
} from "../src/DataTypes.sol";

contract AttestationResolveInstance is AttestationResolve {
    function resolveAttestation(
        ResolverUID resolverUID,
        AttestationRecord memory attestationRecord,
        uint256 value,
        bool isRevocation,
        uint256 availableValue,
        bool isLastAttestation
    )
        public
        returns (uint256)
    {
        return _resolveAttestation(
            resolverUID, attestationRecord, value, isRevocation, availableValue, isLastAttestation
        );
    }

    function resolveAttestations(
        ResolverUID resolverUID,
        AttestationRecord[] memory attestationRecords,
        uint256[] memory values,
        bool isRevocation,
        uint256 availableValue,
        bool isLast
    )
        public
        returns (uint256)
    {
        return _resolveAttestations(
            resolverUID, attestationRecords, values, isRevocation, availableValue, isLast
        );
    }

    // Required by AttestationResolve
    mapping(SchemaUID => SchemaRecord) schemaRecords;
    mapping(ResolverUID => ResolverRecord) resolverRecords;
    mapping(address => ModuleRecord) moduleRecords;

    function _getSchema(SchemaUID schemaUID)
        internal
        view
        override
        returns (SchemaRecord storage)
    {
        return schemaRecords[schemaUID];
    }

    function addResolver(ResolverUID resolverUID, ResolverRecord memory resolverRecord) public {
        resolverRecords[resolverUID] = resolverRecord;
    }

    function getResolver(ResolverUID resolverUID)
        public
        view
        override
        returns (ResolverRecord memory)
    {
        return resolverRecords[resolverUID];
    }

    function _getModule(address moduleAddress)
        internal
        view
        override
        returns (ModuleRecord storage)
    {
        return moduleRecords[moduleAddress];
    }

    // Required by IAttestation
    function attest(AttestationRequest calldata request) external payable { }
    function multiAttest(MultiAttestationRequest[] calldata multiRequests) external payable { }
    function attest(DelegatedAttestationRequest calldata delegatedRequest) external payable { }
    function multiAttest(MultiDelegatedAttestationRequest[] calldata multiDelegatedRequests)
        external
        payable
    { }
    function revoke(RevocationRequest calldata request) external payable { }
    function revoke(DelegatedRevocationRequest calldata request) external payable { }
    function multiRevoke(MultiDelegatedRevocationRequest[] calldata multiDelegatedRequests)
        external
        payable
    { }
    function multiRevoke(MultiRevocationRequest[] calldata multiRequests) external payable { }
}

contract FalseResolver is ResolverBase {
    constructor(address rs) ResolverBase(rs) { }

    function onAttest(
        AttestationRecord calldata attestation,
        uint256 /*value*/
    )
        internal
        view
        override
        returns (bool)
    {
        return false;
    }

    function onRevoke(
        AttestationRecord calldata attestation,
        uint256 value
    )
        internal
        pure
        override
        returns (bool)
    {
        return false;
    }

    function onModuleRegistration(
        ModuleRecord calldata module,
        uint256 value
    )
        internal
        override
        returns (bool)
    {
        return false;
    }
}

contract PayableResolver is ResolverBase {
    constructor(address rs) ResolverBase(rs) { }

    function onAttest(
        AttestationRecord calldata attestation,
        uint256 /*value*/
    )
        internal
        view
        override
        returns (bool)
    {
        return true;
    }

    function onRevoke(
        AttestationRecord calldata attestation,
        uint256 value
    )
        internal
        pure
        override
        returns (bool)
    {
        return true;
    }

    function onModuleRegistration(
        ModuleRecord calldata module,
        uint256 value
    )
        internal
        override
        returns (bool)
    {
        return true;
    }

    function isPayable() public pure override returns (bool) {
        return true;
    }
}

/// @title AttestationResolveTest
/// @author kopy-kat
contract AttestationResolveTest is BaseTest {
    AttestationResolveInstance resolverInstance;
    FalseResolver falseResolver;
    PayableResolver payableResolver;

    function setUp() public override {
        super.setUp();
        resolverInstance = new AttestationResolveInstance();
        falseResolver = new FalseResolver(address(resolverInstance));
        payableResolver = new PayableResolver(address(resolverInstance));

        resolverInstance.addResolver(
            ResolverUID.wrap(0),
            ResolverRecord({
                resolver: IResolver(address(debugResolver)),
                resolverOwner: address(this)
            })
        );

        resolverInstance.addResolver(
            ResolverUID.wrap(bytes32(uint256(1))),
            ResolverRecord({
                resolver: IResolver(address(falseResolver)),
                resolverOwner: address(this)
            })
        );

        resolverInstance.addResolver(
            ResolverUID.wrap(bytes32(uint256(2))),
            ResolverRecord({
                resolver: IResolver(address(payableResolver)),
                resolverOwner: address(this)
            })
        );

        resolverInstance.addResolver(
            ResolverUID.wrap(bytes32(uint256(3))),
            ResolverRecord({ resolver: IResolver(address(0x6969)), resolverOwner: address(this) })
        );
    }

    function testResolveAttestation() public {
        AttestationRecord memory attestationRecord = AttestationRecord({
            schemaUID: defaultSchema1,
            subject: address(this),
            attester: address(this),
            time: uint48(0),
            expirationTime: uint48(0),
            revocationTime: uint48(0),
            dataPointer: AttestationDataRef.wrap(address(0))
        });

        resolverInstance.resolveAttestation({
            resolverUID: ResolverUID.wrap(bytes32(uint256(2))),
            attestationRecord: attestationRecord,
            value: 0,
            isRevocation: false,
            availableValue: 0,
            isLastAttestation: true
        });
    }

    function testResolveAttestation__WithValue() public {
        AttestationRecord memory attestationRecord = AttestationRecord({
            schemaUID: defaultSchema1,
            subject: address(this),
            attester: address(this),
            time: uint48(0),
            expirationTime: uint48(0),
            revocationTime: uint48(0),
            dataPointer: AttestationDataRef.wrap(address(0))
        });

        vm.deal(address(resolverInstance), 2 ether);

        address sender = makeAddr("sender");
        vm.prank(sender);
        resolverInstance.resolveAttestation({
            resolverUID: ResolverUID.wrap(bytes32(uint256(2))),
            attestationRecord: attestationRecord,
            value: 1 ether,
            isRevocation: false,
            availableValue: 2 ether,
            isLastAttestation: true
        });

        assertEq(sender.balance, 1 ether);
    }

    function testResolveAttestation__RevertWhen__ZeroResolverAndValue() public {
        AttestationRecord memory attestationRecord = AttestationRecord({
            schemaUID: defaultSchema1,
            subject: address(this),
            attester: address(this),
            time: uint48(0),
            expirationTime: uint48(0),
            revocationTime: uint48(0),
            dataPointer: AttestationDataRef.wrap(address(0))
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.NotPayable.selector));

        resolverInstance.resolveAttestation({
            resolverUID: ResolverUID.wrap(bytes32(uint256(200_000))),
            attestationRecord: attestationRecord,
            value: 1 wei,
            isRevocation: false,
            availableValue: 0,
            isLastAttestation: true
        });
    }

    function testResolveAttestation__RevertWhen__ResolverNotPayableAndValue() public {
        AttestationRecord memory attestationRecord = AttestationRecord({
            schemaUID: defaultSchema1,
            subject: address(this),
            attester: address(this),
            time: uint48(0),
            expirationTime: uint48(0),
            revocationTime: uint48(0),
            dataPointer: AttestationDataRef.wrap(address(0))
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.NotPayable.selector));

        resolverInstance.resolveAttestation({
            resolverUID: ResolverUID.wrap(bytes32(uint256(0))),
            attestationRecord: attestationRecord,
            value: 1 wei,
            isRevocation: false,
            availableValue: 0,
            isLastAttestation: true
        });
    }

    function testResolveAttestation__RevertWhen__InsufficientValue() public {
        AttestationRecord memory attestationRecord = AttestationRecord({
            schemaUID: defaultSchema1,
            subject: address(this),
            attester: address(this),
            time: uint48(0),
            expirationTime: uint48(0),
            revocationTime: uint48(0),
            dataPointer: AttestationDataRef.wrap(address(0))
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InsufficientValue.selector));

        resolverInstance.resolveAttestation({
            resolverUID: ResolverUID.wrap(bytes32(uint256(2))),
            attestationRecord: attestationRecord,
            value: 2 wei,
            isRevocation: false,
            availableValue: 1 wei,
            isLastAttestation: true
        });
    }

    function testResolveAttestation__RevertWhen__InvalidRevocation() public {
        AttestationRecord memory attestationRecord = AttestationRecord({
            schemaUID: defaultSchema1,
            subject: address(this),
            attester: address(this),
            time: uint48(0),
            expirationTime: uint48(0),
            revocationTime: uint48(0),
            dataPointer: AttestationDataRef.wrap(address(0))
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidRevocation.selector));
        resolverInstance.resolveAttestation({
            resolverUID: ResolverUID.wrap(bytes32(uint256(1))),
            attestationRecord: attestationRecord,
            value: 0,
            isRevocation: true,
            availableValue: 0,
            isLastAttestation: true
        });
    }

    function testResolveAttestation__RevertWhen__InvalidAttestation() public {
        AttestationRecord memory attestationRecord = AttestationRecord({
            schemaUID: defaultSchema1,
            subject: address(this),
            attester: address(this),
            time: uint48(0),
            expirationTime: uint48(0),
            revocationTime: uint48(0),
            dataPointer: AttestationDataRef.wrap(address(0))
        });

        vm.expectRevert(abi.encodeWithSelector(IAttestation.InvalidAttestation.selector));
        resolverInstance.resolveAttestation({
            resolverUID: ResolverUID.wrap(bytes32(uint256(1))),
            attestationRecord: attestationRecord,
            value: 0,
            isRevocation: false,
            availableValue: 0,
            isLastAttestation: true
        });
    }
}
