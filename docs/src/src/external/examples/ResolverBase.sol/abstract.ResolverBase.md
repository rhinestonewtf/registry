# ResolverBase
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/external/examples/ResolverBase.sol)

**Inherits:**
[IExternalResolver](/src/external/IExternalResolver.sol/interface.IExternalResolver.md)


## State Variables
### REGISTRY

```solidity
IRegistry internal immutable REGISTRY;
```


## Functions
### constructor


```solidity
constructor(IRegistry _registry);
```

### onlyRegistry


```solidity
modifier onlyRegistry();
```

