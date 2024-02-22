# ResolverManager
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/ResolverManager.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md)


## State Variables
### $resolvers

```solidity
mapping(ResolverUID uid => ResolverRecord resolver) internal $resolvers;
```


## Functions
### onlyResolverOwner

*Modifier to require that the caller is the owner of a resolver*


```solidity
modifier onlyResolverOwner(ResolverUID uid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|The UID of the resolver.|


### onlyResolver

If a resolver is not address(0), we check if it supports the IExternalResolver interface


```solidity
modifier onlyResolver(IExternalResolver resolver);
```

### registerResolver

Allows Marketplace Agents to register external resolvers.


```solidity
function registerResolver(IExternalResolver resolver) external onlyResolver(resolver) returns (ResolverUID uid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`resolver`|`IExternalResolver`|external resolver contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|ResolverUID of the registered resolver|


### setResolver

Entities that previously regsitered an external resolver, may update the implementation address.


```solidity
function setResolver(ResolverUID uid, IExternalResolver resolver) external onlyResolver(resolver) onlyResolverOwner(uid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|The UID of the resolver.|
|`resolver`|`IExternalResolver`|The new resolver implementation address.|


### transferResolverOwnership

Transfer ownership of resolverUID to a new address


```solidity
function transferResolverOwnership(ResolverUID uid, address newOwner) external onlyResolverOwner(uid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|The UID of the resolver to transfer ownership for|
|`newOwner`|`address`|The address of the new owner|


### findResolver

Getter function to get the ResolverRecord of a registerd resolver


```solidity
function findResolver(ResolverUID uid) external view returns (ResolverRecord memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|The UID of the resolver.|


