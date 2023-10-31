// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import "forge-std/Test.sol";

// import "./Attestation.t.sol";
// import "../src/interface/IQuery.sol";

// /// @title RSRegistryTest
// /// @author zeroknots

// contract QueryTest is AttestationTest {
//     using RegistryTestLib for RegistryInstance;

//     function setUp() public virtual override {
//         super.setUp();
//     }

//     function testQueryAttestation() public {
//         testAttest();

//         AttestationRecord memory attestation1 =
//             instance.registry.findAttestation(defaultModule1, vm.addr(auth1k));
//     }

//     function testCheckAttestation() public {
//         testAttest();
//         instance.registry.check(defaultModule1, vm.addr(auth1k));
//     }

//     function testCheckAttestation__RevertWhen__Unlisted() public {
//         vm.expectRevert(IQuery.AttestationNotFound.selector);
//         instance.registry.check(defaultModule1, vm.addr(auth1k));
//     }

//     function testCheckAttestation__RevertWhen__Expired() public {
//         vm.warp(100);
//         AttestationRequestData memory attData = AttestationRequestData({
//             subject: defaultModule1,
//             expirationTime: uint48(101),
//             data: abi.encode(true),
//             value: 0
//         });
//         instance.mockAttestation(defaultSchema1, auth1k, attData);
//         vm.warp(200);
//         vm.expectRevert(IQuery.AttestationNotFound.selector);
//         instance.registry.check(defaultModule1, vm.addr(auth1k));
//     }

//     function testCheckAttestation__RevertWhen__Revoked() public {
//         testAttest();
//         instance.revokeAttestation(defaultModule1, defaultSchema1, address(this));
//         vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, vm.addr(auth1k)));
//         instance.registry.check(defaultModule1, vm.addr(auth1k));
//     }

//     function testCheckNAttestation() public {
//         testAttest();
//         AttestationRequestData memory attData = AttestationRequestData({
//             subject: defaultModule1,
//             expirationTime: uint48(101),
//             data: abi.encode(true),
//             value: 0
//         });
//         instance.mockAttestation(defaultSchema1, auth2k, attData);
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);
//         instance.registry.checkN(defaultModule1, authorities, 1);
//     }

//     function testCheckNAttestation__RevertWhen__ThresholdNotMet() public {
//         testAttest();
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);

//         vm.expectRevert(IQuery.InsufficientAttestations.selector);
//         instance.registry.checkN(defaultModule1, authorities, 2);
//     }

//     function testCheckNAttestation__RevertWhen__Expired() public {
//         vm.warp(100);
//         testAttest();
//         AttestationRequestData memory attData = AttestationRequestData({
//             subject: defaultModule1,
//             expirationTime: uint48(101),
//             data: abi.encode(true),
//             value: 0
//         });
//         instance.mockAttestation(defaultSchema1, auth2k, attData);
//         vm.warp(200);
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);

//         vm.expectRevert(IQuery.AttestationNotFound.selector);
//         instance.registry.checkN(defaultModule1, authorities, 1);
//     }

//     function testCheckNAttestation__RevertWhen__Revoked() public {
//         testAttest();
//         AttestationRequestData memory attData = AttestationRequestData({
//             subject: defaultModule1,
//             expirationTime: uint48(101),
//             data: abi.encode(true),
//             value: 0
//         });
//         instance.mockAttestation(defaultSchema1, auth2k, attData);
//         instance.revokeAttestation(defaultModule1, defaultSchema1, address(this));
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);

//         vm.expectRevert(abi.encodeWithSelector(IQuery.RevokedAttestation.selector, vm.addr(auth2k)));
//         instance.registry.checkN(defaultModule1, authorities, 1);
//     }

//     function testCheckNAttestationUnsafe() public {
//         testAttest();
//         AttestationRequestData memory attData = AttestationRequestData({
//             subject: defaultModule1,
//             expirationTime: uint48(101),
//             data: abi.encode(true),
//             value: 0
//         });
//         instance.mockAttestation(defaultSchema1, auth2k, attData);
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);
//         instance.registry.checkNUnsafe(defaultModule1, authorities, 1);
//     }

//     function testCheckNAttestationUnsafe__RevertWhen__ThresholdNotMet() public {
//         testAttest();
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);

//         vm.expectRevert(IQuery.InsufficientAttestations.selector);
//         instance.registry.checkNUnsafe(defaultModule1, authorities, 2);
//     }

//     function testCheckNAttestationUnsafe__Expired() public {
//         vm.warp(100);
//         testAttest();
//         AttestationRequestData memory attData = AttestationRequestData({
//             subject: defaultModule1,
//             expirationTime: uint48(101),
//             data: abi.encode(true),
//             value: 0
//         });
//         instance.mockAttestation(defaultSchema1, attData);
//         vm.warp(200);
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);

//         instance.registry.checkNUnsafe(defaultModule1, authorities, 1);
//     }

//     function testCheckNAttestationUnsafe__Revoked() public {
//         testAttest();
//         AttestationRequestData memory attData = AttestationRequestData({
//             subject: defaultModule1,
//             expirationTime: uint48(101),
//             data: abi.encode(true),
//             value: 0
//         });
//         instance.mockAttestation(defaultSchema1, attData);
//         instance.revokeAttestation(defaultModule1, defaultSchema1, address(this));
//         address[] memory authorities = new address[](2);
//         authorities[0] = vm.addr(auth1k);
//         authorities[1] = vm.addr(auth2k);

//         instance.registry.checkNUnsafe(defaultModule1, authorities, 1);
//     }
// }
