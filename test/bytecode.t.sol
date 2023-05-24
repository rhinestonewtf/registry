// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

contract NoParams {
    address public owner;

    constructor() {
        // owner = _owner;
    }
}

contract WithParams {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }
}

/// @title BytecodeTest
/// @author zeroknots
contract BytecodeTest is Test {
    function setUp() public { }

    function testDeployPackedParams() public {
        bytes memory codeA =
            abi.encodePacked(type(WithParams).creationCode, abi.encode(address(0x1234)));

        bytes memory codeB =
            abi.encodePacked(type(WithParams).creationCode, abi.encode(address(0x1235)));

        address deployedA = deploy(codeA, 1);
        console2.log("deployedAddrA", deployedA);
        assertEq(keccak256(deployedA.code), getCodeHash(deployedA));

        address deployedB = deploy(codeB, 1);
        console2.log("deployedAddrB", deployedB);
        assertEq(keccak256(deployedB.code), getCodeHash(deployedB));

        // assertEq(keccak256(deployedA.code), keccak256(deployedB.code));

        assertEq(keccak256(abi.encodePacked(type(WithParams).creationCode)), getCodeHash(deployedA));

        address deployedC = deploy(codeA, abi.encode(address(0xbeef)), 2);
        console2.log("deployedAddrC", deployedC);

        // bytes memory creationCodeD = type(WithParams).creationCode;
        // bytes memory paramsD = abi.encode(address(0x1234));
        // address deployedD = deploy(creationCodeD, paramsD, 1);
        // console2.log("deployedAddrD", deployedD);

        // address deployedE = deploy(codeA, "", 1);
        // console2.log("deployedAddrE", deployedE);
    }

    function testEvaluateParams() public {
        address depl =
            deploy(abi.encodePacked(type(WithParams).creationCode, abi.encode(address(0x1234))), 1);

        // getCode from deployed contract
        bytes memory code = address(depl).code;
        bytes memory foo = abi.encodePacked(code, abi.encode(address(0x1234)));
        address verify = getAddress(foo, 1);
        assertEq(verify, address(depl));
    }

    function deploy(
        bytes memory createCode,
        bytes memory params,
        uint256 salt
    )
        internal
        returns (address moduleAddress)
    {
        bytes memory code = abi.encodePacked(createCode, params);

        if (getAddress(code, salt) == getAddress(createCode, salt)) {
            console2.log("paramsInCode");
        }
        return deploy(code, salt);
    }

    function testCalcHash() public {
        //
        //
        // bytes memory code = abi.encodePacked(
        //   type(MockContract).creationCode
        //   // abi.encode(address(0x1234))
        // );
        //
        // bytes memory code2 = abi.encodePacked(
        //   type(MockContract).creationCode,
        //   abi.encode(address(0x1235))
        // );
        //
        // address calcAddr = getAddress(code, 1);
        // address deployedAddr = deploy(code, 1);
        // address deployedAddr2 = deploy(code2, 1);
        //
        // console2.log("calcAddr", calcAddr);
        // console2.log("deployedAddr", deployedAddr);
        // console2.log(".code");
        // console2.logBytes32(keccak256(address(deployedAddr).code));
        //
        // console2.log(".creationData");
        // console2.logBytes32(keccak256(code));
        //
        // console2.log(".creationCode");
        // console2.logBytes32(keccak256(type(MockContract).creationCode));
        //
        // console2.log("extcode");
        // console2.logBytes32(getCodeHash(deployedAddr));
        // console2.logBytes32(getCodeHash(deployedAddr2));
        //
        // /**
        //
        //   if no constructur params:
        //     keccack(deployBytecode) == extcodehash
        //
        //   if constructor params:
        //       address.code == extcode
        //
        //
        //
        //   */
        //
    }

    function deploy(bytes memory code, uint256 salt) internal returns (address moduleAddress) {
        assembly {
            moduleAddress := create2(0, add(code, 0x20), mload(code), salt)
            // If the contract was not created successfully, the transaction is reverted.
            if iszero(extcodesize(moduleAddress)) { revert(0, 0) }
        }
    }

    function getAddress(bytes memory bytecode, uint256 _salt) public view returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(bytecode)));

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    function getCodeHash(address contractAddr) internal view returns (bytes32 codeHash) {
        assembly {
            codeHash := extcodehash(contractAddr)
        }
    }
}
