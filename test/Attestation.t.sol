// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

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
        request = AttestationRequest({
            moduleAddr: module,
            expirationTime: expirationTime,
            data: data,
            moduleTypes: typesEnc
        });
    }

    function mockRevocation(address module)
        internal
        pure
        returns (RevocationRequest memory request)
    {
        request = RevocationRequest({ moduleAddr: module });
    }

    function test_WhenAttestingWithNoAttestationData(address module)
        public
        prankWithAccount(attester1)
    {
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request =
            mockAttestation(module, uint48(block.timestamp + 1), "", types);
        // It should store.
        registry.attest(defaultSchemaUID, request);
        AttestationRecord memory record = registry.readAttestation(module, attester1.addr);

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        assertEq(record.moduleAddr, request.moduleAddr);
        assertEq(record.attester, attester1.addr);
    }

    function test_WhenAttestingWithExpirationTimeInThePast(
        address module,
        bytes memory data,
        uint32 moduleType
    )
        external
    {
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
        address module,
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

        expirationTime = uint48(block.timestamp + expirationTime + 100);
        AttestationRequest memory request = mockAttestation(module, expirationTime, data, types);
        // It should revert.
        vm.expectRevert(); // TODO: should we allow counterfactual?
        registry.attest(defaultSchemaUID, request);
    }

    function test_WhenRevokingAttestationThatDoesntExist(address module)
        external
        prankWithAccount(attester1)
    {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.AttestationNotFound.selector));
        registry.revoke(mockRevocation(module));
    }

    function test_WhenAttesting_ShouldCallResolver() external {
        resolverTrue.reset();
        // It should call ExternalResolver.

        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request =
            mockAttestation(makeAddr("module"), uint48(block.timestamp + 1), "", types);
        // It should store.
        // TODO: it seems that the resolver is not being called
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

    function test_WhenUsingValidECDSA() external whenAttestingWithSignature {
        uint256 nonceBefore = registry.attesterNonce(attester1.addr);
        // It should recover.
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request =
            mockAttestation(makeAddr("module"), uint48(block.timestamp + 100), "", types);

        bytes32 digest = registry.getDigest(request, attester1.addr);
        bytes memory sig = ecdsaSign(attester1.key, digest);
        registry.attest(defaultSchemaUID, attester1.addr, request, sig);

        AttestationRecord memory record =
            registry.readAttestation(makeAddr("module"), attester1.addr);
        uint256 nonceAfter = registry.attesterNonce(attester1.addr);

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        assertEq(record.moduleAddr, request.moduleAddr);
        assertEq(record.attester, attester1.addr);
        assertEq(nonceAfter, nonceBefore + 1);
    }

    function test_WhenUsingInvalidECDSA() external whenAttestingWithSignature {
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request =
            mockAttestation(makeAddr("module"), uint48(block.timestamp + 100), "", types);

        bytes32 digest = registry.getDigest(request, attester1.addr);
        bytes memory sig = ecdsaSign(attester1.key, digest);
        sig = abi.encodePacked(sig, "foo");
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidSignature.selector));
        registry.attest(defaultSchemaUID, attester1.addr, request, sig);
    }

    function test_WhenUsingValidERC1271() external whenAttestingWithSignature {
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request =
            mockAttestation(makeAddr("module"), uint48(block.timestamp + 100), "", types);

        bytes memory sig = "signature";
        registry.attest(defaultSchemaUID, address(erc1271AttesterTrue), request, sig);

        AttestationRecord memory record =
            registry.readAttestation(makeAddr("module"), address(erc1271AttesterTrue));

        assertEq(record.time, block.timestamp);
        assertEq(record.expirationTime, request.expirationTime);
        assertEq(record.moduleAddr, request.moduleAddr);
        assertEq(record.attester, address(erc1271AttesterTrue));
    }

    function test_WhenUsingInvalidERC1271() external whenAttestingWithSignature {
        // It should revert.
        uint32[] memory types = new uint32[](1);
        AttestationRequest memory request =
            mockAttestation(makeAddr("module"), uint48(block.timestamp + 100), "", types);

        bytes memory sig = "signature";
        vm.expectRevert(abi.encodeWithSelector(IRegistry.InvalidSignature.selector));
        registry.attest(defaultSchemaUID, address(erc1271AttesterFalse), request, sig);
    }

    function ecdsaSign(
        uint256 privKey,
        bytes32 digest
    )
        internal
        pure
        returns (bytes memory signature)
    {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
