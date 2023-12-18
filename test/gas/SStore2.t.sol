// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import {
    Attestation,
    MultiDelegatedAttestationRequest,
    AttestationRecord,
    IAttestation,
    InvalidSchema,
    NotFound,
    AccessDenied
} from "../../src/base/Attestation.sol";

import { ERC1271Attester, EXPECTED_SIGNATURE } from "../utils/ERC1271Attester.sol";

import {
    BaseTest,
    RegistryTestLib,
    RegistryInstance,
    console2,
    AttestationRequestData,
    DelegatedAttestationRequest,
    MockModuleWithArgs,
    ResolverUID,
    IResolver,
    SchemaUID,
    ISchemaValidator
} from "../utils/BaseTest.t.sol";

import {
    MultiAttestationRequest,
    MultiRevocationRequest,
    RevocationRequestData,
    RevocationRequest
} from "../../src/DataTypes.sol";

struct SampleAttestation {
    address[] dependencies;
    string comment;
    string url;
    bytes32 hash;
    uint256 severity;
}

/// @title SStore2GasCalculations
/// @author kopy-kat
contract SStore2GasCalculations is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }

    function testAttest() public {
        AttestationRequestData memory attData = AttestationRequestData({
            subject: defaultModule1,
            expirationTime: uint48(200_000),
            data: abi.encode(true),
            value: 0
        });

        AttestationRequestData memory attData2 = AttestationRequestData({
            subject: defaultModule2,
            expirationTime: uint48(200_000),
            data: abi.encode(true),
            value: 0
        });

        uint256 gas = gasleft();
        instance.newAttestation(defaultSchema1, attData);
        // gas = gas - gasleft();
        instance.newAttestation(defaultSchema1, attData2);
        gas = gas - gasleft();
        console2.log(gas);
    }
}
