# TokenizedResolver
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/external/examples/TokenizedResolver.sol)

**Inherits:**
[ResolverBase](/src/external/examples/ResolverBase.sol/abstract.ResolverBase.md)


## State Variables
### TOKEN

```solidity
IERC20 public immutable TOKEN;
```


### fee

```solidity
uint256 internal immutable fee = 1e18;
```


## Functions
### constructor


```solidity
constructor(IERC20 _token, IRegistry _registry) ResolverBase(_registry);
```

### supportsInterface


```solidity
function supportsInterface(bytes4 interfaceID) external view override returns (bool);
```

### resolveAttestation


```solidity
function resolveAttestation(AttestationRecord calldata attestation) external payable override onlyRegistry returns (bool);
```

### resolveAttestation


```solidity
function resolveAttestation(AttestationRecord[] calldata attestation) external payable override onlyRegistry returns (bool);
```

### resolveRevocation


```solidity
function resolveRevocation(AttestationRecord calldata attestation) external payable override onlyRegistry returns (bool);
```

### resolveRevocation


```solidity
function resolveRevocation(AttestationRecord[] calldata attestation) external payable override onlyRegistry returns (bool);
```

### resolveModuleRegistration


```solidity
function resolveModuleRegistration(
    address sender,
    address moduleAddress,
    ModuleRecord calldata record
)
    external
    payable
    override
    onlyRegistry
    returns (bool);
```

