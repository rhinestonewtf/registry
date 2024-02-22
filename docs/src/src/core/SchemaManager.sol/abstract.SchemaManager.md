# SchemaManager
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/SchemaManager.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md)

**Author:**
rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)


## State Variables
### schemas

```solidity
mapping(SchemaUID uid => SchemaRecord schemaRecord) internal schemas;
```


## Functions
### registerSchema

Register Schema and (optional) external IExternalSchemaValidator
Schemas describe the structure of the data of attestations
every attestation made on this registry, will reference a SchemaUID to
make it possible to decode attestation data in human readable form
overrwriting a schema is not allowed, and will revert


```solidity
function registerSchema(
    string calldata schema,
    IExternalSchemaValidator validator
)
    external
    onlySchemaValidator(validator)
    returns (SchemaUID uid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schema`|`string`|ABI schema used to encode attestations that are made with this schema|
|`validator`|`IExternalSchemaValidator`|(optional) external schema validator that will be used to validate attestations. use address(0), if you dont need an external validator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`SchemaUID`|SchemaUID of the registered schema|


### onlySchemaValidator

If a validator is not address(0), we check if it supports the IExternalSchemaValidator interface


```solidity
modifier onlySchemaValidator(IExternalSchemaValidator validator);
```

### findSchema

getter function to retrieve SchemaRecord


```solidity
function findSchema(SchemaUID uid) external view override returns (SchemaRecord memory);
```

