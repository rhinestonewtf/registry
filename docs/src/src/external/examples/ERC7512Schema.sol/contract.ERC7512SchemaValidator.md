# ERC7512SchemaValidator
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/external/examples/ERC7512Schema.sol)

**Inherits:**
[IExternalSchemaValidator](/src/external/IExternalSchemaValidator.sol/interface.IExternalSchemaValidator.md), [ERC7512](/src/external/examples/ERC7512Schema.sol/interface.ERC7512.md)


## Functions
### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceID) external pure override returns (bool);
```

### validateSchema


```solidity
function validateSchema(AttestationRecord calldata attestation) public view override returns (bool valid);
```

### validateSchema


```solidity
function validateSchema(AttestationRecord[] calldata attestations) external view override returns (bool valid);
```

