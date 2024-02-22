# ModuleManager
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/ModuleManager.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md), [ResolverManager](/src/core/ResolverManager.sol/abstract.ResolverManager.md)

**Author:**
rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)

*The Module contract is responsible for handling the registration,
storage and retrieval of modules on the Registry.
This contract inherits from the IModule interface*

*The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
that has been deployed through the Module. The details of each module, such as its address, code hash, schema ID,
sender address, deploy parameters hash, and additional metadata are stored in
a struct and mapped to the module's address in
the `_modules` mapping for easy access and management.*

*In conclusion, the Module is a central part of a system to manage,
deploy, and interact with a set of smart contracts
in a structured and controlled manner.*


## State Variables
### $moduleAddrToRecords

```solidity
mapping(address moduleAddress => ModuleRecord moduleRecord) internal $moduleAddrToRecords;
```


## Functions
### deployModule

This registry implements a CREATE2 factory, that allows module developers to register and deploy module bytecode


```solidity
function deployModule(
    bytes32 salt,
    ResolverUID resolverUID,
    bytes calldata initCode,
    bytes calldata metadata
)
    external
    payable
    returns (address moduleAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`salt`|`bytes32`|The salt to be used in the CREATE2 factory. This adheres to Pr000xy/Create2Factory.sol salt formatting. The salt's first bytes20 should be the address of the sender or bytes20(0) to bypass the check (this will lose replay protection)|
|`resolverUID`|`ResolverUID`|The resolverUID to be used in the CREATE2 factory|
|`initCode`|`bytes`|The initCode to be used in the CREATE2 factory|
|`metadata`|`bytes`|The metadata to be stored on the registry. This field is optional, and might be used by the module developer to store additional information about the module or facilitate business logic with the Resolver stub|


### calcModuleAddress

in conjunction with the deployModule() function, this function let's you
predict the address of a CREATE2 module deployment


```solidity
function calcModuleAddress(bytes32 salt, bytes calldata initCode) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`salt`|`bytes32`|CREATE2 salt|
|`initCode`|`bytes`|module initcode|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|moduleAddress counterfactual address of the module deployment|


### registerModule

Already deployed module addresses can be registered on the registry


```solidity
function registerModule(ResolverUID resolverUID, address moduleAddress, bytes calldata metadata) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`resolverUID`|`ResolverUID`|The resolverUID to be used for the module|
|`moduleAddress`|`address`|The address of the module to be registered|
|`metadata`|`bytes`|The metadata to be stored on the registry. This field is optional, and might be used by the module developer to store additional information about the module or facilitate business logic with the Resolver stub|


### deployViaFactory

Registry can use other factories to deploy the module


```solidity
function deployViaFactory(
    address factory,
    bytes calldata callOnFactory,
    bytes calldata metadata,
    ResolverUID resolverUID
)
    external
    payable
    returns (address moduleAddress);
```

### _storeModuleRecord


```solidity
function _storeModuleRecord(
    address moduleAddress,
    address sender,
    ResolverUID resolverUID,
    bytes calldata metadata
)
    internal
    returns (ModuleRecord memory moduleRegistration);
```

### findModule

Getter function to get the stored ModuleRecord for a specific module address.


```solidity
function findModule(address moduleAddress) external view returns (ModuleRecord memory moduleRecord);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleAddress`|`address`|The address of the module|


