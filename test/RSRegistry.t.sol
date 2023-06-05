// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "solmate/test/utils/mocks/MockERC20.sol";

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
import "../src/interface/IRSAuthority.sol";

import "./mock/MockAuthority.sol";
import { MockTokenizedAuthority } from "./mock/MockTokenizedAuthority.sol";

contract MockContract {
    address owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function foo() external pure returns (uint256) {
        return 1;
    }
}

library HashiTestLib {
    function toUint256Array(bytes32[] memory array) internal pure returns (uint256[] memory) {
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
        RSRegistry.Module memory contractArtifacts =
            _getArtifacts({ registry: registryL1, contractImpl: newContract });

        _dispatchToL2(contractArtifacts);
    }

    function testDeployAndReRegister() public {
        bytes memory code = type(MockContract).creationCode;
        bytes memory params = abi.encode(dev);
        bytes memory packd = abi.encodePacked(code, params);

        address deployedContract = registryL1.deploy(code, params, 1, "");

        vm.expectRevert(abi.encodeWithSelector(AlreadyRegistered.selector, deployedContract));
        registryL1.register(deployedContract, params, "");
    }

    function testQueryRegistry() public {
        MockContract newContractInstance = new MockContract(dev);
        _regContract({
            asUser: dev,
            contractrAddr: address(newContractInstance),
            params: abi.encode(dev)
        });

        _verifyContract({ asAuthority: authority1, moduleAddr: address(newContractInstance) });

        registryL1.fetchAttestation({
            moduleAddr: address(newContractInstance),
            authority: authority1,
            acceptedRisk: 128
        });
    }

    function testPollMultipleAuthorities() public {
        MockAuthority mockAuthorityContract1 = new MockAuthority();
        MockAuthority mockAuthorityContract2 = new MockAuthority();

        MockContract newContractInstance = new MockContract(dev);

        IRSAuthority[] memory authoritiesToQuery = new IRSAuthority[](2);
        authoritiesToQuery[0] = IRSAuthority(address(mockAuthorityContract1));
        authoritiesToQuery[1] = IRSAuthority(address(mockAuthorityContract2));

        vm.expectRevert(
            abi.encodeWithSelector(
                SecurityAlert.selector,
                address(newContractInstance),
                address(mockAuthorityContract1)
            )
        );
        registryL1.fetchAttestation(authoritiesToQuery, address(newContractInstance), 2);

        RSRegistry.Attestation memory verification = RSRegistry.Attestation({
            risk: 1,
            confidence: 1,
            state: RSRegistry.AttestationState.Verified,
            codeHash: "",
            data: ""
        });

        mockAuthorityContract1.setAttestation(address(newContractInstance), verification);
        mockAuthorityContract2.setAttestation(address(newContractInstance), verification);
        registryL1.fetchAttestation(authoritiesToQuery, address(newContractInstance), 2);
    }

    function testTokenizedAuthority() public {
        MockERC20 erc20 = new MockERC20("foo", "FOO", 18);

        MockTokenizedAuthority mockAuthorityContract1 = new MockTokenizedAuthority(address(erc20));
        MockAuthority mockAuthorityContract2 = new MockAuthority();

        MockContract newContractInstance = new MockContract(dev);

        IRSAuthority[] memory authoritiesToQuery = new IRSAuthority[](2);
        authoritiesToQuery[0] = IRSAuthority(address(mockAuthorityContract1));
        authoritiesToQuery[1] = IRSAuthority(address(mockAuthorityContract2));

        vm.expectRevert(abi.encodeWithSelector(MockTokenizedAuthority.InvalidLicense.selector));
        registryL1.fetchAttestation(authoritiesToQuery, address(newContractInstance), 2);

        erc20.mint(address(this), 10);

        RSRegistry.Attestation memory verification = RSRegistry.Attestation({
            risk: 1,
            confidence: 1,
            state: RSRegistry.AttestationState.Verified,
            codeHash: "",
            data: ""
        });

        mockAuthorityContract1.setAttestation(address(newContractInstance), verification);
        mockAuthorityContract2.setAttestation(address(newContractInstance), verification);
        registryL1.fetchAttestation(authoritiesToQuery, address(newContractInstance), 2);
    }

    /*//////////////////////////////////////////////////////////////
                            Helper Function
    //////////////////////////////////////////////////////////////*/

    function _dispatchToL2(RSRegistry.Module memory contractArtifacts) public {
        Message[] memory messages;
        bytes32[] memory messageIdsBytes32;
        (messages, messageIdsBytes32) = (
            registryL1.dispatchAttestation(
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

        RSRegistry.Module memory artifactsL2 =
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
        address moduleAddr
    )
        internal
        returns (RSRegistry.Module memory)
    {
        vm.prank(asAuthority);
        registryL1.verify(
            moduleAddr,
            10,
            10,
            "",
            RSRegistryLib.codeHash(moduleAddr),
            RSRegistry.AttestationState.Verified
        );
        return _getArtifacts(registryL1, moduleAddr);
    }

    function _getArtifacts(
        RSRegistry registry,
        address contractImpl
    )
        internal
        view
        returns (RSRegistry.Module memory)
    {
        (
            address impl,
            bytes32 codeHash,
            bytes32 deployParamsHash,
            address sender,
            bytes memory data
        ) = registryL1.modules(contractImpl);
        RSRegistry.Module memory contractArtifacts = RSRegistry.Module({
            implementation: impl,
            codeHash: codeHash,
            deployParamsHash: deployParamsHash,
            sender: sender,
            data: data
        });
        return contractArtifacts;
    }
}
