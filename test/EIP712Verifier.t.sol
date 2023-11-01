// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BaseTest, RegistryTestLib, RegistryInstance } from "./utils/BaseTest.t.sol";
import { EIP712Verifier } from "../src/base/EIP712Verifier.sol";

struct SampleAttestation {
    address[] dependencies;
    string comment;
    string url;
    bytes32 hash;
    uint256 severity;
}

contract EIP712VerifierInstance is EIP712Verifier { }

/// @title EIP712VerifierTest
/// @author kopy-kat
contract EIP712VerifierTest is BaseTest {
    using RegistryTestLib for RegistryInstance;

    function setUp() public virtual override {
        super.setUp();
    }
}
