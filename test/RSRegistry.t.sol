// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "hashi/Yaho.sol";
import "hashi/Yaru.sol";
import "hashi/Hashi.sol";
import "hashi/interfaces/IHashi.sol";
import "hashi/interfaces/IOracleAdapter.sol";
import { Message } from "hashi/interfaces/IMessageDispatcher.sol";
import "hashi/GiriGiriBashi.sol";

import "hashi/adapters/AMB/AMBAdapter.sol";
import "hashi/adapters/AMB/IAMB.sol";
import "hashi/adapters/AMB/AMBMessageRelayer.sol";
import "hashi/adapters/AMB/test/MockAMB.sol";

import "../src/RSRegistry.sol";

contract MockContract {
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function foo() external returns (uint256) {
        return 1;
    }
}

library HashiTestLib {
    function toUint256Array(bytes32[] memory array) internal returns (uint256[] memory) {
        uint256[] memory array2 = new uint256[](array.length);
        for (uint256 i; i < array.length; ++i) {
            array2[i] = uint256(array[i]);
        }
        return array2;
    }
}

/// @title HashiTest
/// @author zeroknots
contract HashiTest is Test {
    using HashiTestLib for bytes32[];

    Yaho yaho;
    Yaru yaru;
    Hashi hashi;
    GiriGiriBashi giriGiriBashi;
    AMBAdapter ambAdapter;
    AMBMessageRelay ambMessageRelay;
    MockAMB amb;

    RSRegistry registryL1;
    RSRegistry registryL2;

    address signer = makeAddr("signer");

    address dev = makeAddr("dev");
    address authority1 = makeAddr("authority1");

    function setUp() public {
        hashi = new Hashi();
        giriGiriBashi = new GiriGiriBashi(signer, address(hashi));
        yaho = new Yaho();
        amb = new MockAMB();
        yaru = new Yaru(IHashi(address(hashi)), address(yaho), block.chainid);

        ambMessageRelay = new AMBMessageRelay(IAMB(address(amb)),yaho);
        ambAdapter =
            new AMBAdapter(IAMB(address(amb)), address(ambMessageRelay), bytes32(block.chainid));

        registryL1 = new RSRegistry(yaho, yaru, address(0));
        registryL2 = new RSRegistry(yaho, yaru, address(registryL1));
    }

    function testRegisterExistingContract() public returns (address newContract) {
        vm.prank(dev);
        MockContract newContractInstance = new MockContract(dev);
        newContract = address(newContractInstance);
        _regContract(dev, newContract, abi.encode(dev));
    }

    function testDeploy() public {
        bytes memory code = type(MockContract).creationCode;
        bytes memory params = abi.encode(dev);

        bytes memory packd = abi.encodePacked(code, params);

        address deployment = registryL1.deploy(code, params, 1, "");

        bytes memory params2 = abi.encode(address(0x1234));
        address deployment2 = registryL1.deploy(code, params2, 1, "");
    }

    function testDispatch() public {
        address newContract = testRegisterExistingContract();
        _verifyContract(authority1, newContract);
        RSRegistry.ContractArtifact memory contractArtifacts =
            _getArtifacts({ registry: registryL1, contractImpl: newContract });

        _dispatchToL2(contractArtifacts);
    }

    

    /*//////////////////////////////////////////////////////////////
                            Helper Function
    //////////////////////////////////////////////////////////////*/

    function _dispatchToL2(RSRegistry.ContractArtifact memory contractArtifacts) public {
        Message[] memory messages;
        bytes32[] memory messageIdsBytes32;
        (messages, messageIdsBytes32) = (
            registryL1.dispatchVerification(
                contractArtifacts.implementation, authority1, block.chainid, address(registryL2)
            )
        );

        uint256[] memory messageIds = messageIdsBytes32.toUint256Array();
        address[] memory adapters = new address[](1);
        adapters[0] = address(ambMessageRelay);

        address[] memory destinationAdapters = new address[](1);
        destinationAdapters[0] = address(ambAdapter);
        yaho.relayMessagesToAdapters(messageIds, adapters, destinationAdapters);

        address[] memory senders = new address[](1);
        senders[0] = address(registryL1);

        IOracleAdapter[] memory oracleAdapter = new IOracleAdapter[](1);
        oracleAdapter[0] = IOracleAdapter(address(ambAdapter));

        yaru.executeMessages(messages, messageIds, senders, oracleAdapter);

        RSRegistry.ContractArtifact memory artifactsL2 =
            _getArtifacts(registryL2, contractArtifacts.implementation);

        assertEq(artifactsL2.codeHash, contractArtifacts.codeHash);
        assertEq(artifactsL2.sender, contractArtifacts.sender);
        assertEq(artifactsL2.implementation, contractArtifacts.implementation);
    }

    function _regContract(
        address asUser,
        address contractrAddr,
        bytes memory params
    )
        internal
        returns (bytes32 codeHash)
    {
        vm.prank(asUser);
        return registryL1.register(contractrAddr, params, "");
    }

    function _verifyContract(
        address asAuthority,
        address contractrAddr
    )
        internal
        returns (RSRegistry.ContractArtifact memory)
    {
        vm.prank(asAuthority);
        registryL1.verify(contractrAddr, 10, 10, "", RSRegistryLib.getCodeHash(contractrAddr));
        return _getArtifacts(registryL1, contractrAddr);
    }

    function _getArtifacts(
        RSRegistry registry,
        address contractImpl
    )
        internal
        returns (RSRegistry.ContractArtifact memory)
    {
        (address impl, bytes32 codeHash, address sender, bytes memory data) =
            registryL1.contracts(contractImpl);
        RSRegistry.ContractArtifact memory contractArtifacts = RSRegistry.ContractArtifact({
            implementation: impl,
            codeHash: codeHash,
            sender: sender,
            data: data
        });
        return contractArtifacts;
    }
}
