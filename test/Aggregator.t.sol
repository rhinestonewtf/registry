// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import "./TrustDelegation.t.sol";
import { PackedUserOperation } from "@ERC4337/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract AggregatorTest is TrustTest {
    function setUp() public override {
        super.setUp();

        address[] memory attesters = new address[](1);
        attesters[0] = address(attester1.addr);
        _make_WhenUsingValidECDSA(attester1);
        test_WhenSupplyingManyAttesters(1, attesters);
    }

    function test_aggregate() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = PackedUserOperation({
            sender: smartAccount1.addr,
            nonce: getNonce(1, address(module1)),
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
            preVerificationGas: 2e6,
            gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
            paymasterAndData: bytes(""),
            signature: abi.encodePacked(hex"41414141")
        });

        // userOps[1] = PackedUserOperation({
        //     sender: smartAccount2.addr,
        //     nonce: getNonce(1, address(module1)),
        //     initCode: "",
        //     callData: "",
        //     accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
        //     preVerificationGas: 2e6,
        //     gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
        //     paymasterAndData: bytes(""),
        //     signature: abi.encodePacked(hex"41414141")
        // });
        bytes memory sig = registry.aggregateSignatures(userOps);

        registry.validateSignatures(userOps, sig);
    }

    function getNonce(uint256 _nonce, address validator) internal view returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = _nonce | uint256(key) << 64;
    }

    function signatureInNonce(
        address account,
        uint256 nonce,
        PackedUserOperation memory userOp,
        address validator,
        bytes memory signature
    )
        internal
        view
        returns (PackedUserOperation memory)
    {
        userOp.nonce = getNonce(nonce, validator);
        userOp.signature = signature;

        return userOp;
    }
}
