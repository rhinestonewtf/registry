// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "src/Registry.sol";
import "src/DataTypes.sol";
import "./mocks/MockResolver.sol";
import "./mocks/MockSchemaValidator.sol";
import "./mocks/MockERC1271Attester.sol";
import "./mocks/MockModule.sol";

contract BaseTest is Test {
    Registry registry;

    Account smartAccount1;
    Account smartAccount2;

    Account attester1;
    Account attester2;

    Account moduleDev1;
    Account moduleDev2;

    Account opsEntity1;
    Account opsEntity2;

    MockResolver resolverFalse;
    MockResolver resolverTrue;

    MockSchemaValidator schemaValidatorFalse;
    MockSchemaValidator schemaValidatorTrue;

    MockERC1271Attester erc1271AttesterFalse;
    MockERC1271Attester erc1271AttesterTrue;

    MockModule module1;
    MockModule module2;
    MockModule module3;

    string defaultSchema = "Foobar";
    SchemaUID defaultSchemaUID;
    ResolverUID defaultResolverUID;

    function setUp() public virtual {
        vm.warp(1_641_070_800);
        registry = new Registry();

        smartAccount1 = makeAccount("smartAccount1");
        smartAccount2 = makeAccount("smartAccount2");

        attester1 = makeAccount("attester1");
        attester2 = makeAccount("attester2");

        moduleDev1 = makeAccount("moduleDev1");
        moduleDev2 = makeAccount("moduleDev2");

        opsEntity1 = makeAccount("opsEntity1");
        opsEntity2 = makeAccount("opsEntity2");

        resolverFalse = new MockResolver(false);
        resolverTrue = new MockResolver(true);

        schemaValidatorFalse = new MockSchemaValidator(false);
        schemaValidatorTrue = new MockSchemaValidator(true);

        erc1271AttesterFalse = new MockERC1271Attester(false);
        erc1271AttesterTrue = new MockERC1271Attester(true);

        module1 = new MockModule();
        module2 = new MockModule();
        module3 = new MockModule();

        initDefaultEnv();
    }

    modifier prankWithAccount(Account memory account) {
        vm.startPrank(account.addr);
        _;
        vm.stopPrank();
    }

    function initDefaultEnv() internal {
        vm.prank(opsEntity1.addr);
        defaultResolverUID = registry.registerResolver(IExternalResolver(address(resolverTrue)));
        vm.prank(opsEntity1.addr);
        defaultSchemaUID = registry.registerSchema(
            defaultSchema, IExternalSchemaValidator(address(schemaValidatorTrue))
        );

        vm.prank(moduleDev1.addr);
        registry.registerModule(defaultResolverUID, address(module1), "");
        vm.prank(moduleDev2.addr);
        registry.registerModule(defaultResolverUID, address(module2), "");
    }
}
