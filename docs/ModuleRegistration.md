
# Module Registration
The Module Registration function is used to deploy new smart account modules onto the Ethereum network. 
The function uses the CREATE2/CREATE3, allowing the contract to determine the address where the smart 
account module will be deployed before the actual deployment transaction is sent. 
The registration process requires one schema ID to be associated with the new module.

Every module is registered with a corsponding resolverUID.


```solidity

struct ModuleRecord {
    ResolverUID resolverUID; // The unique identifier of the Resolver
    address implementation; // The deployed contract address
    address sender; // The address of the sender who deployed the contract
    bytes data; // Additional data related to the contract deployment
}
```

## Module Deployment

The registry supports different ways to register modules.


![Sequence Diagram](../public/docs/module-registration.svg)

## Deploy Bytecode via Registry (CREATE2)

Module Developers can deploy their module Bytecode directly with the registry.
The chosed resolver will be used to validate the deployment.


```solidity
/**
 * @notice Deploys a new module.
 *
 * @dev Ensures the resolver is valid and then deploys the module.
 *
 * @param code The bytecode for the module.
 * @param deployParams Parameters required for deployment.
 * @param salt Salt for creating the address.
 * @param data Data associated with the module.
 * @param resolverUID Unique ID of the resolver.
 *
 * @return moduleAddr The address of the deployed module.
 */
function deploy(
    bytes calldata code,
    bytes calldata deployParams,
    bytes32 salt,
    bytes calldata data,
    ResolverUID resolverUID
)
    external
    payable
    returns (address moduleAddr);
```

## Deploy Bytecode via Registry (CREATE3)
Module Developers can deploy their module Bytecode directly with the registry.
The Registry supports deployments via CREATE3 so the initcode of the module does not affect the modules deployment address. 
This feature can be very useful for cross-chain deployments.

```solidity
/**
 * @notice Deploys a new module using the CREATE3 method.
 *
 * @dev Similar to the deploy function but uses CREATE3 for deployment.
 * @dev the salt supplied here will be hashed again with msg.sender
 *
 * @param code The bytecode for the module.
 * @param deployParams Parameters required for deployment.
 * @param salt Initial salt for creating the final salt.
 * @param data Data associated with the module.
 * @param resolverUID Unique ID of the resolver.
 *
 * @return moduleAddr The address of the deployed module.
 */
function deployC3(
    bytes calldata code,
    bytes calldata deployParams,
    bytes32 salt,
    bytes calldata data,
    ResolverUID resolverUID
)
    external
    payable
    returns (address moduleAddr);

```

The CREATE2 salt is calculated like this:
```solidity
bytes32 senderSalt = keccak256(abi.encodePacked(salt, msg.sender));

```

## Deploy Bytecode via External Factory

In order to make the integration into existing business logics possible, 
the registry is able to utilize external factories that can be utilized to deploy the modules.

```solidity
/**
 * @notice Deploys a new module via an external factory contract.
 *
 * @param factory Address of the factory contract.
 * @param callOnFactory Encoded call to be made on the factory contract.
 * @param data Data associated with the module.
 * @param resolverUID Unique ID of the resolver.
 *
 * @return moduleAddr The address of the deployed module.
 */
function deployViaFactory(
    address factory,
    bytes calldata callOnFactory,
    bytes calldata data,
    ResolverUID resolverUID
)
    external
    payable
    returns (address moduleAddr);

```



## Register existing Module


After deploying the module bytecode, the registry saves the deployment address as well as the chosen `resolverUID`, 
in addition to the following metadata.

```solidity
/**
 * @notice Registers an existing module with the contract.
 *
 * @param resolverUID Unique ID of the resolver.
 * @param moduleAddress Address of the module.
 * @param data Data associated with the module.
 */
function register(
    ResolverUID resolverUID,
    address moduleAddress,
    bytes calldata data
)
    external;

```
