// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./Base.t.sol";
import "src/DataTypes.sol";

contract AttestationTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
    }

    function mockAttestation(
        address module,
        uint48 expirationTime,
        bytes memory data,
        uint32[] memory types
    )
        internal
        pure
        returns (AttestationRequest memory request)
    {
        ModuleType[] memory typesEnc = new ModuleType[](types.length);
        for (uint256 i; i < types.length; i++) {
            typesEnc[i] = ModuleType.wrap(types[i]);
        }
        request = AttestationRequest({ moduleAddress: module, expirationTime: expirationTime, data: data, moduleTypes: typesEnc });
    }

    function mockRevocation(address module) internal pure returns (RevocationRequest memory request) {
        request = RevocationRequest({ moduleAddress: module });
    }

    function test_WhenAttestingWithNoAttestationData() public prankWithAccount(attester1) {
        address module = address(new MockModule());
        registry.registerModule(defaultResolverUID, module, "", "");
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request = mockAttestation(module, uint48(block.timestamp + 1), "", types);
        // It should store.
        registry.attest(defaultSchemaUID, request);
        AttestationRecord memory record = registry.findAttestation(module, attester1.addr);

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        assertEq(record.moduleAddress, request.moduleAddress);
        assertEq(record.attester, attester1.addr);
    }

    function test_WhenUsingValidMulti() public prankWithAccount(attester1) {
        // It should recover.
        uint32[] memory types = new uint32[](1);

        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        registry.attest(defaultSchemaUID, requests);

        AttestationRecord memory record = registry.findAttestation(address(module1), attester1.addr);

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, requests[0].expirationTime);
        assertEq(record.moduleAddress, requests[0].moduleAddress);
        assertEq(record.attester, attester1.addr);
    }

    function test_WhenUsingInvalidSchemaUIDAttestation() public prankWithAccount(attester1) {
        // It should recover.
        uint32[] memory types = new uint32[](1);

        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        vm.expectRevert();
        registry.attest(SchemaUID.wrap(bytes32("1234")), requests);
    }

    function test_WhenUsingInvalidSchemaUIDRevocation() public prankWithAccount(attester1) {
        // It should recover.
        uint32[] memory types = new uint32[](1);

        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        registry.attest(defaultSchemaUID, requests);
        AttestationRequest memory request = mockAttestation(address(module3), uint48(block.timestamp + 100), "", types);
        registry.attest(defaultSchemaUID, request);

        RevocationRequest[] memory revocations = new RevocationRequest[](2);
        revocations[0] = mockRevocation(address(module2));
        revocations[1] = mockRevocation(address(module3));

        vm.expectRevert();
        registry.revoke(revocations);
    }

    function test_WhenUsingValidMultiDifferentResolver__ShouldRevert() public prankWithAccount(attester1) {
        // It should recover.
        uint32[] memory types = new uint32[](1);

        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module3), uint48(block.timestamp + 100), "", types);

        vm.expectRevert();
        registry.attest(defaultSchemaUID, requests);
    }

    function test_WhenUsingValidMulti__Revocation() public {
        test_WhenUsingValidMulti();

        RevocationRequest[] memory requests = new RevocationRequest[](2);
        requests[0] = mockRevocation(address(module1));
        requests[1] = mockRevocation(address(module2));

        vm.prank(attester2.addr);
        vm.expectRevert();
        registry.revoke(requests);
        vm.prank(attester1.addr);
        registry.revoke(requests);
        vm.expectRevert();
        registry.revoke(requests);
    }

    function test_findAttestation() public {
        // It should recover.
        uint32[] memory types = new uint32[](1);

        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        vm.prank(attester1.addr);
        registry.attest(defaultSchemaUID, requests);
        vm.prank(attester2.addr);
        registry.attest(defaultSchemaUID, requests);

        address[] memory attesters = new address[](2);
        attesters[0] = attester1.addr;
        attesters[1] = attester2.addr;
        AttestationRecord[] memory record = registry.findAttestations(address(module1), attesters);

        assertEq(record[0].time, block.timestamp);
        assertEq(record[0].expirationTime, requests[0].expirationTime);
        assertEq(record[0].moduleAddress, requests[0].moduleAddress);
        assertEq(record[0].attester, attester1.addr);

        assertEq(record[1].time, block.timestamp);
        assertEq(record[1].expirationTime, requests[0].expirationTime);
        assertEq(record[1].moduleAddress, requests[0].moduleAddress);
        assertEq(record[1].attester, attester2.addr);
    }

    function test_WhenReAttestingToARevokedAttestation() public prankWithAccount(attester1) {
        address module = address(new MockModule());
        registry.registerModule(defaultResolverUID, module, "", "");
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request = mockAttestation(module, uint48(block.timestamp + 1), "", types);
        // It should store.
        registry.attest(defaultSchemaUID, request);
        AttestationRecord memory record = registry.findAttestation(module, attester1.addr);

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        assertEq(record.revocationTime, 0);
        assertEq(record.moduleAddress, request.moduleAddress);
        assertEq(record.attester, attester1.addr);

        RevocationRequest memory revocation = RevocationRequest({ moduleAddress: module });

        vm.warp(block.timestamp + 100);
        registry.revoke(revocation);

        record = registry.findAttestation({ module: module, attester: attester1.addr });
        assertEq(record.revocationTime, block.timestamp);
        vm.warp(block.timestamp + 100);

        request.expirationTime = uint48(block.timestamp + 100);
        registry.attest(defaultSchemaUID, request);
        record = registry.findAttestation({ module: module, attester: attester1.addr });
        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        // ensure revocation time is reset
        assertEq(record.revocationTime, 0);
        assertEq(record.moduleAddress, request.moduleAddress);
        assertEq(record.attester, attester1.addr);
    }

    function test_WhenAttestingWithExpirationTimeInThePast(address module, bytes memory data, uint32 moduleType) external {
        vm.assume(moduleType > 31);
        uint48 expirationTime = uint48(block.timestamp - 1000);

        uint32[] memory types = new uint32[](1);
        types[0] = moduleType;
        AttestationRequest memory request = mockAttestation(module, expirationTime, data, types);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidExpirationTime.selector));
        registry.attest(defaultSchemaUID, request);
    }

    function test_WhenAttestingWithTooHighModuleType(
        address module,
        uint48 expirationTime,
        bytes memory data,
        uint32 moduleType
    )
        external
    {
        vm.assume(moduleType > 31);
        // ensure that the expiration time is in the future
        // function test_WhenAttestingWithExpirationTimeInThePast covers this
        expirationTime = uint48(block.timestamp + expirationTime);
        uint32[] memory types = new uint32[](1);
        types[0] = moduleType;
        AttestationRequest memory request = mockAttestation(module, expirationTime, data, types);

        // It should revert.
        vm.expectRevert();
        registry.attest(defaultSchemaUID, request);
    }

    function test_WhenAttestingToNon_existingModule(
        uint32 moduleFuzz,
        uint48 expirationTime,
        bytes memory data,
        uint32[] memory types
    )
        external
        prankWithAccount(attester1)
    {
        for (uint256 i; i < types.length; i++) {
            vm.assume(types[i] < 32);
        }

        vm.assume(moduleFuzz != 0);
        address module = vm.addr(moduleFuzz);

        expirationTime = uint48(block.timestamp + expirationTime + 100);
        AttestationRequest memory request = mockAttestation(module, expirationTime, data, types);
        // It should revert.
        vm.expectRevert();
        registry.attest(defaultSchemaUID, request);
    }

    function test_WhenRevokingAttestationThatDoesntExist(address module) external prankWithAccount(attester1) {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.AttestationNotFound.selector));
        registry.revoke(mockRevocation(module));
    }

    function test_WhenAttesting_ShouldCallResolver() external {
        resolverTrue.reset();
        // It should call ExternalResolver.

        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request = mockAttestation(address(module1), uint48(block.timestamp + 1), "", types);
        // It should store.
        registry.attest(defaultSchemaUID, request);

        assertTrue(resolverTrue.onAttestCalled());
    }

    modifier whenAttestingWithTokenomicsResolver() {
        _;
    }

    function test_WhenTokensArePaid() external whenAttestingWithTokenomicsResolver {
        // It should work.
    }

    function test_WhenTokensAreNotPaid() external whenAttestingWithTokenomicsResolver {
        // It should revert.
    }

    modifier whenAttestingWithSignature() {
        _;
    }

    modifier whenRevokingWithSignature() {
        _;
    }

    function test_WhenUsingValidECDSA() public whenAttestingWithSignature {
        _make_WhenUsingValidECDSA(attester1);
    }

    function _make_WhenUsingValidECDSA(Account memory attester) public whenAttestingWithSignature {
        uint256 nonceBefore = registry.attesterNonce(attester.addr);
        // It should recover.
        uint32[] memory types = new uint32[](2);
        types[0] = 1;
        types[1] = 2;
        AttestationRequest memory request = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);

        bytes32 digest = registry.getDigest(request, attester.addr);
        bytes memory sig = ecdsaSign(attester.key, digest);
        registry.attest(defaultSchemaUID, attester.addr, request, sig);

        AttestationRecord memory record = registry.findAttestation(address(module1), attester.addr);
        uint256 nonceAfter = registry.attesterNonce(attester.addr);

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        assertEq(record.moduleAddress, request.moduleAddress);
        assertEq(record.attester, attester.addr);
        assertEq(nonceAfter, nonceBefore + 1);
        assertEq(PackedModuleTypes.unwrap(record.moduleTypes), 2 ** 1 + 2 ** 2);
    }

    function test_WhenRevokingWithValidECDSA() public {
        test_WhenUsingValidECDSA();

        RevocationRequest memory request = mockRevocation(address(module1));
        bytes32 digest = registry.getDigest(request, attester1.addr);
        bytes memory sig = ecdsaSign(attester1.key, digest);
        registry.revoke(attester1.addr, request, sig);
    }

    function test_WhenRevokingWithValidECDSAMulti() public {
        test_WhenUsingValidECDSAMulti();

        RevocationRequest[] memory requests = new RevocationRequest[](2);
        requests[0] = mockRevocation(address(module1));
        requests[1] = mockRevocation(address(module2));
        bytes32 digest = registry.getDigest(requests, attester1.addr);
        bytes memory sig = ecdsaSign(attester1.key, digest);
        registry.revoke(attester1.addr, requests, sig);
    }

    function test_WhenUsingValidECDSAMulti() public whenAttestingWithSignature {
        uint256 nonceBefore = registry.attesterNonce(attester1.addr);
        // It should recover.
        uint32[] memory types = new uint32[](1);

        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        bytes32 digest = registry.getDigest(requests, attester1.addr);
        bytes memory sig = ecdsaSign(attester1.key, digest);
        registry.attest(defaultSchemaUID, attester1.addr, requests, sig);

        AttestationRecord memory record = registry.findAttestation(address(module1), attester1.addr);
        uint256 nonceAfter = registry.attesterNonce(attester1.addr);

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, requests[0].expirationTime);
        assertEq(record.moduleAddress, requests[0].moduleAddress);
        assertEq(record.attester, attester1.addr);
        assertEq(nonceAfter, nonceBefore + 1);
    }

    function test_WhenUsingInvalidECDSA() external whenAttestingWithSignature {
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);

        bytes32 digest = registry.getDigest(request, attester1.addr);
        bytes memory sig = ecdsaSign(attester1.key, digest);
        sig = abi.encodePacked(sig, "foo");
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidSignature.selector));
        registry.attest(defaultSchemaUID, attester1.addr, request, sig);
    }

    function test_WhenUsingInvalidECDSAMulti() external whenAttestingWithSignature {
        uint32[] memory types = new uint32[](1);
        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        bytes32 digest = registry.getDigest(requests, attester1.addr);
        bytes memory sig = ecdsaSign(attester1.key, digest);
        sig = abi.encodePacked(sig, "foo");
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidSignature.selector));
        registry.attest(defaultSchemaUID, attester1.addr, requests, sig);
    }

    function test_WhenUsingValidERC1271() external whenAttestingWithSignature {
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);

        bytes memory sig = "signature";
        registry.attest(defaultSchemaUID, address(erc1271AttesterTrue), request, sig);

        AttestationRecord memory record = registry.findAttestation(address(module1), address(erc1271AttesterTrue));

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        assertEq(record.moduleAddress, request.moduleAddress);
        assertEq(record.attester, address(erc1271AttesterTrue));
    }

    function test_WhenUsingValidERC1271Multi() external whenAttestingWithSignature {
        uint32[] memory types = new uint32[](1);
        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        bytes memory sig = "signature";
        registry.attest(defaultSchemaUID, address(erc1271AttesterTrue), requests, sig);

        AttestationRecord memory record = registry.findAttestation(address(module1), address(erc1271AttesterTrue));

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, requests[0].expirationTime);
        assertEq(record.moduleAddress, requests[0].moduleAddress);
        assertEq(record.attester, address(erc1271AttesterTrue));
    }

    function test_WhenUsingInvalidERC1271Multi() external whenAttestingWithSignature {
        // It should revert.
        uint32[] memory types = new uint32[](1);

        AttestationRequest[] memory requests = new AttestationRequest[](2);
        requests[0] = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);
        requests[1] = mockAttestation(address(module2), uint48(block.timestamp + 100), "", types);

        bytes memory sig = "signature";
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidSignature.selector));
        registry.attest(defaultSchemaUID, address(erc1271AttesterFalse), requests, sig);
    }

    function test_WhenUsingInvalidERC1271() external whenAttestingWithSignature {
        // It should revert.
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request = mockAttestation(address(module1), uint48(block.timestamp + 100), "", types);

        bytes memory sig = "signature";
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidSignature.selector));
        registry.attest(defaultSchemaUID, address(erc1271AttesterFalse), request, sig);
    }

    function ecdsaSign(uint256 privKey, bytes32 digest) internal pure returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
