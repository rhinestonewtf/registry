import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

import "src/Registry.sol";
import "src/DataTypes.sol";
import "src/external/IExternalSchemaValidator.sol";
import "src/external/IExternalResolver.sol";
import "../mocks/MockSchemaValidator.sol";
import "../mocks/MockResolver.sol";
import "../mocks/MockFactory.sol";
import { LibSort } from "solady/utils/LibSort.sol";

contract Handler is CommonBase, StdCheats, StdUtils {
    Registry immutable REGISTRY;
    MockFactory immutable FACTORY;

    using LibSort for uint256[];

    constructor(Registry _registry) {
        REGISTRY = _registry;
        FACTORY = new MockFactory();
    }

    function handle_registerResolver() public returns (ResolverUID) {
        MockResolver resolverTrue = new MockResolver(true);
        return REGISTRY.registerResolver(IExternalResolver(address(resolverTrue)));
    }

    function handle_setResolver() external {
        ResolverUID uid = handle_registerResolver();
        MockResolver resolverTrue = new MockResolver(true);

        REGISTRY.setResolver(uid, resolverTrue);
    }

    function _pickRandomSchemaUID(uint256 nr) internal returns (SchemaUID uid) {
        SchemaUID[] memory uids = new SchemaUID[](5);
        uids[0] = handle_registerSchema("schema1");
        uids[1] = handle_registerSchema("schema2");
        uids[2] = handle_registerSchema("schema3");
        uids[3] = handle_registerSchema("schema4");
        uids[4] = handle_registerSchema("schema5");

        return uids[nr % 5];
    }

    function _pickRandomResolverUID(uint256 nr) internal returns (ResolverUID uid) {
        ResolverUID[] memory uids = new ResolverUID[](5);
        uids[0] = handle_registerResolver();
        uids[1] = handle_registerResolver();
        uids[2] = handle_registerResolver();
        uids[3] = handle_registerResolver();
        uids[4] = handle_registerResolver();

        return uids[nr % 5];
    }

    function handle_registerSchema(string memory schema) public returns (SchemaUID uid) {
        MockSchemaValidator schemaValidatorTrue = new MockSchemaValidator(true);
        uid = REGISTRY.registerSchema(schema, IExternalSchemaValidator(address(schemaValidatorTrue)));
        SchemaRecord memory record = REGISTRY.findSchema(uid);
    }

    function handle_registerModule(uint256 randomResolverNr, address moduleAddr, bytes calldata bytecode, bytes calldata metadata) public {
        vm.etch(moduleAddr, bytecode);
        ResolverUID uid = _pickRandomResolverUID(randomResolverNr);

        REGISTRY.registerModule(uid, moduleAddr, metadata);
    }

    function _pickTypes() private pure returns (ModuleType[] memory ret) {
        ret = new ModuleType[](3);
        ret[0] = ModuleType.wrap(1);
        ret[1] = ModuleType.wrap(2);
        ret[2] = ModuleType.wrap(3);
    }

    function handle_attest(
        uint256 randResolv,
        bytes calldata bytecode,
        bytes calldata metadata,
        uint256 randomSchemaUID,
        AttestationRequest memory request
    )
        public
    {
        bound(request.expirationTime, block.timestamp + 1, type(uint48).max);
        request.moduleTypes = _pickTypes();

        handle_registerModule(randResolv, request.moduleAddr, bytecode, metadata);
        SchemaUID uid = _pickRandomSchemaUID(randomSchemaUID);

        REGISTRY.attest(uid, request);
    }

    function handle_attests(
        uint256 randResolv,
        bytes calldata bytecode,
        bytes calldata metadata,
        uint256 randomSchemaUID,
        AttestationRequest[] memory requests
    )
        public
    {
        // for (uint256 i = 0; i < requests.length; i++) {
        //     bound(requests[i].expirationTime, block.timestamp + 1, type(uint48).max);
        //     requests[i].moduleTypes = _pickTypes();
        //     handle_registerModule(randResolv, requests[i].moduleAddr, bytecode, metadata);
        // }
        //
        SchemaUID uid = _pickRandomSchemaUID(randomSchemaUID);

        REGISTRY.attest(uid, requests);
    }

    function handle_registerModuleWithFactory(uint256 randomResolverNr, bytes calldata bytecode, uint256 value) external {
        vm.deal(address(this), value);
        ResolverUID uid = _pickRandomResolverUID(randomResolverNr);
        REGISTRY.deployViaFactory{ value: value }(address(FACTORY), abi.encodeCall(MockFactory.deploy, (bytecode)), "", uid);
    }
}
