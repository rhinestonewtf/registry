# UIDLib
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/lib/Helpers.sol)


## Functions
### getUID

*Calculates a UID for a given schema.*


```solidity
function getUID(SchemaRecord memory schemaRecord) internal view returns (SchemaUID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schemaRecord`|`SchemaRecord`|The input schema.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`SchemaUID`|schema UID.|


### getUID

*Calculates a UID for a given resolver.*


```solidity
function getUID(ResolverRecord memory resolver) internal view returns (ResolverUID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`resolver`|`ResolverRecord`|The input schema.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`ResolverUID`|ResolverUID.|


