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

import "../../src/registry/RSGenericRegistry.sol";

contract MockContract {
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function foo() external returns (uint256) {
        return 1;
    }
}

/// @title HashiTest
/// @author zeroknots
contract HashiTest is Test {
    Yaho yaho;
    Yaru yaru;
    Hashi hashi;
    GiriGiriBashi giriGiriBashi;
    AMBAdapter ambAdapter;
    AMBMessageRelay ambMessageRelay;
    MockAMB amb;

    RSGenericRegistry registryL1;
    RSGenericRegistry registryL2;

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

        registryL1 = new RSGenericRegistry(yaho, yaru, address(0));
        registryL2 = new RSGenericRegistry(yaho, yaru, address(registryL1));
    }

    function mockRegistration() public returns (RSGenericRegistry.ContractArtifact memory) {
        MockContract mock = new MockContract(signer);
        vm.prank(dev);
        registryL1.register(address(mock), "");

        vm.prank(authority1);
        registryL1.verify(
            address(mock), 10, 10, "", RSGenericRegistryLib.getCodeHash(address(mock))
        );

        return getContractArtifactsFromRegistry(registryL1, address(mock));
    }

    function getContractArtifactsFromRegistry(
        RSGenericRegistry registry,
        address contractImpl
    )
        internal
        returns (RSGenericRegistry.ContractArtifact memory)
    {
        (address impl, bytes32 codeHash, address sender, bytes memory data) =
            registryL1.contracts(contractImpl);
        RSGenericRegistry.ContractArtifact memory contractArtifacts = RSGenericRegistry
            .ContractArtifact({ implementation: impl, codeHash: codeHash, sender: sender, data: data });
        return contractArtifacts;
    }

    function bytes32ToUint256(bytes32[] memory array) internal returns (uint256[] memory) {
        uint256[] memory array2 = new uint256[](array.length);
        for (uint256 i; i < array.length; ++i) {
            array2[i] = uint256(array[i]);
        }
        return array2;
    }

    function testDeploy() public {
        bytes memory code = type(MockContract).creationCode;
        bytes memory params = abi.encode(dev);

        bytes memory packd = abi.encodePacked(code, params);

        address deployment = registryL1.deploy(code, params, 1, "");

        bytes memory params2 = abi.encode(address(0x1234));
        address deployment2 = registryL1.deploy(code, params2, 1, "");
    }

    function testBridgeMessage() public {
        RSGenericRegistry.ContractArtifact memory contractArtifacts = mockRegistration();

        Message[] memory messages;
        bytes32[] memory messageIdsBytes32;
        (messages, messageIdsBytes32) = (
            registryL1.dispatchVerification(
                contractArtifacts.implementation, authority1, block.chainid, address(registryL2)
            )
        );

        uint256[] memory messageIds = bytes32ToUint256(messageIdsBytes32);
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

        RSGenericRegistry.ContractArtifact memory artifactsL2 =
            getContractArtifactsFromRegistry(registryL2, contractArtifacts.implementation);

        assertEq(artifactsL2.codeHash, contractArtifacts.codeHash);
        assertEq(artifactsL2.sender, contractArtifacts.sender);
        assertEq(artifactsL2.implementation, contractArtifacts.implementation);
    }
}

