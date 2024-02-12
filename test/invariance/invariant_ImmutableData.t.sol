import "src/IRegistry.sol";
import "../Base.t.sol";
import "./Handler.t.sol";

contract ImmutableData is BaseTest {
    AttestationDataRef defaultDataRef;
    Handler handler;

    function setUp() public override {
        super.setUp();
        handler = new Handler(registry);

        AttestationRecord memory attRecord =
            registry.findAttestation(address(module1), invarAttester.addr);
        defaultDataRef = attRecord.dataPointer;

        bytes4[] memory targetSelectors = new bytes4[](6);
        targetSelectors[0] = Handler.handle_registerSchema.selector;
        targetSelectors[1] = Handler.handle_registerResolver.selector;
        targetSelectors[2] = Handler.handle_setResolver.selector;
        targetSelectors[3] = Handler.handle_registerModule.selector;
        targetSelectors[4] = Handler.handle_attest.selector;
        targetSelectors[5] = Handler.handle_registerModuleWithFactory.selector;
        // targetSelectors[3] = Handler.handle_revoke.selector;

        targetContract(address(handler));
        targetSelector(FuzzSelector({ addr: address(handler), selectors: targetSelectors }));
    }

    function invariant_resolver_immutable() public { }

    function invariant_schema_immutable() public {
        SchemaRecord memory record = registry.findSchema(defaultSchemaUID);
        assertEq(record.schema, defaultSchema);
    }

    function invariant_attestation_immutable() public {
        AttestationRecord memory record =
            registry.findAttestation(address(module1), invarAttester.addr);
        assertTrue(record.dataPointer == defaultDataRef);
        assertEq(record.moduleAddr, address(module1));
        assertEq(record.attester, invarAttester.addr);
        assertTrue(record.attester != address(0));
    }

    function invariant_balance() public {
        assertEq(address(registry).balance, 0);
    }
}
