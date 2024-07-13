// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script, console2 } from "forge-std/Script.sol";
import { SafeSingletonDeployer } from "safe-singleton-deployer/SafeSingletonDeployer.sol";
import { Registry } from "src/Registry.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { MockResolver } from "test/mocks/MockResolver.sol";
import { MockSchemaValidator } from "test/mocks/MockSchemaValidator.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

struct Proxy {
    address implementation;
    address proxy;
}

struct EnvironmentSingletons {
    address deployer;
    address registry;
    Proxy schemaValidator;
    Proxy resolver;
}

contract DeployAll is Script {
    address constant SAFE_PROXY_FACTORY = address(0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67);
    address constant SAFE_SINGLETON = address(0x29fcB43b46531BcA003ddC8FCB67FFE91900C762);
    address constant MULTI_SEND = address(0x38869bf66a61cF6bDB996A6aE40D5853Fd43B526);
    address constant ENTRYPOINT = address(0x0000000071727De22E5E9d8BAf0edAc6f37da032);

    function run() public virtual {
        console2.log("Deployment on chainId:", block.chainid);

        uint256 privKey = vm.envUint("PRIVATE_KEY");
        console2.log("Deployer Addr: ", vm.addr(privKey));
        EnvironmentSingletons memory env;
        env.registry = _registry(privKey);

        env.schemaValidator.implementation = _schemaValidator(privKey);
        env.resolver.implementation = _resolver(privKey, env.registry);
        // env.schemaValidator.proxy = _proxy({
        //     pKey: privKey,
        //     implementation: env.schemaValidator.implementation,
        //     admin: env.attesterSafe,
        //     salt: vm.envBytes32("SCHEMA_VALIDATOR_PROXY_SALT"),
        //     initializer: ""
        // });
        // env.resolver.proxy = _proxy({
        //     pKey: privKey,
        //     implementation: env.resolver.implementation,
        //     admin: env.attesterSafe,
        //     salt: vm.envBytes32("RESOLVER_PROXY_SALT"),
        //     initializer: ""
        // });

        _logJson(env);
        _print(env);
    }

    function _registry(uint256 pKey) internal returns (address registry) {
        registry = SafeSingletonDeployer.broadcastDeploy({
            deployerPrivateKey: pKey,
            creationCode: type(Registry).creationCode,
            salt: vm.envBytes32("REGISTRY_SALT")
        });
        _initCode("Registry", type(Registry).creationCode, "");
    }

    function _schemaValidator(uint256 pKey) internal returns (address schemaValidator) {
        schemaValidator = SafeSingletonDeployer.broadcastDeploy({
            deployerPrivateKey: pKey,
            creationCode: type(MockSchemaValidator).creationCode,
            args: abi.encode(true),
            salt: vm.envBytes32("SCHEMA_VALIDATOR_SALT")
        });
    }

    function _proxy(
        uint256 pKey,
        address implementation,
        address admin,
        bytes32 salt,
        bytes memory initializer
    )
        internal
        returns (address proxy)
    {
        proxy = SafeSingletonDeployer.broadcastDeploy({
            deployerPrivateKey: pKey,
            creationCode: type(TransparentUpgradeableProxy).creationCode,
            args: abi.encode(implementation, admin, initializer),
            salt: salt
        });
    }

    function _resolver(uint256 pKey, address registry) internal returns (address resolver) {
        resolver = SafeSingletonDeployer.broadcastDeploy({
            deployerPrivateKey: pKey,
            creationCode: type(MockResolver).creationCode,
            args: abi.encode(true),
            salt: vm.envBytes32("RESOLVER_SALT")
        });
    }

    function _logJson(EnvironmentSingletons memory env) internal {
        string memory root = "some key";
        vm.serializeUint(root, "chainId", block.chainid);
        vm.serializeAddress(root, "broadcastEOA", env.deployer);

        string memory deployments = "deployments";

        string memory item = "registry";
        vm.serializeAddress(item, "address", env.registry);
        vm.serializeBytes32(item, "salt", vm.envBytes32("REGISTRY_SALT"));
        vm.serializeAddress(item, "deployer", env.deployer);
        item = vm.serializeAddress(item, "factory", SafeSingletonDeployer.SAFE_SINGLETON_FACTORY);
        vm.serializeString(deployments, "registry", item);

        string memory schemaValidator = "schemaValidator";
        string memory implementation = "schemaValidator implementation";
        vm.serializeAddress(implementation, "address", env.schemaValidator.implementation);
        vm.serializeBytes32(implementation, "salt", vm.envBytes32("SCHEMA_VALIDATOR_SALT"));
        vm.serializeAddress(implementation, "deployer", env.deployer);
        implementation = vm.serializeAddress(implementation, "factory", SafeSingletonDeployer.SAFE_SINGLETON_FACTORY);
        vm.serializeString(schemaValidator, "implementation", implementation);

        string memory schemaValidatorProxy = "schemaValidator proxy";
        vm.serializeAddress(schemaValidatorProxy, "address", env.schemaValidator.proxy);
        vm.serializeBytes32(schemaValidatorProxy, "salt", vm.envBytes32("SCHEMA_VALIDATOR_PROXY_SALT"));
        vm.serializeAddress(schemaValidatorProxy, "deployer", env.deployer);
        schemaValidatorProxy = vm.serializeAddress(schemaValidatorProxy, "factory", SafeSingletonDeployer.SAFE_SINGLETON_FACTORY);
        schemaValidator = vm.serializeString(schemaValidator, "proxy", schemaValidatorProxy);

        vm.serializeString(deployments, "schemaValidator", schemaValidator);

        string memory resolver = "resolver";
        string memory resolverImplementation = "resolver implementation";
        vm.serializeAddress(resolverImplementation, "address", env.resolver.implementation);
        vm.serializeBytes32(resolverImplementation, "salt", vm.envBytes32("SCHEMA_VALIDATOR_SALT"));
        vm.serializeAddress(resolverImplementation, "deployer", env.deployer);
        resolverImplementation = vm.serializeAddress(resolverImplementation, "factory", SafeSingletonDeployer.SAFE_SINGLETON_FACTORY);
        vm.serializeString(resolver, "implementation", resolverImplementation);

        string memory resolverProxy = "resolverProxy proxy";
        vm.serializeAddress(resolverProxy, "address", env.resolver.proxy);
        vm.serializeBytes32(resolverProxy, "salt", vm.envBytes32("SCHEMA_VALIDATOR_PROXY_SALT"));
        vm.serializeAddress(resolverProxy, "deployer", env.deployer);
        resolverProxy = vm.serializeAddress(resolverProxy, "factory", SafeSingletonDeployer.SAFE_SINGLETON_FACTORY);
        resolver = vm.serializeString(resolver, "proxy", resolverProxy);

        vm.serializeString(deployments, "resolver", resolver);

        string memory output = vm.serializeUint(deployments, "timestamp", block.timestamp);
        string memory finalJson = vm.serializeString(root, "deployments", output);

        string memory fileName = string(abi.encodePacked("./deployments/", Strings.toString(block.chainid), ".json"));
        console2.log("Writing to file: ", fileName);

        vm.writeJson(finalJson, fileName);
    }

    function _print(EnvironmentSingletons memory env) internal pure {
        console2.log("-------------------------------------------------------");
        console2.log("registry:", env.registry);
        console2.log("schemaValidator:", env.schemaValidator.implementation);
        console2.log("schemaValidatorProxy:", env.schemaValidator.proxy);
        console2.log("resolver:", env.resolver.implementation);
        console2.log("resolverProxy:", env.resolver.proxy);
        console2.log("-------------------------------------------------------");
    }

    function _initCode(string memory component, bytes memory creationCode, bytes memory args) private pure {
        console2.log("InitCodeHash: ", component);
        console2.logBytes32(keccak256(abi.encodePacked(creationCode, args)));
        console2.log("\n");
    }
}
