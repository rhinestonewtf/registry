# IERC7484
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/IRegistry.sol)


## Functions
### check


```solidity
function check(address module) external view;
```

### checkForAccount


```solidity
function checkForAccount(address smartAccount, address module) external view;
```

### check


```solidity
function check(address module, ModuleType moduleType) external view;
```

### checkForAccount


```solidity
function checkForAccount(address smartAccount, address module, ModuleType moduleType) external view;
```

### check


```solidity
function check(address module, address attester) external view returns (uint256 attestedAt);
```

### checkN


```solidity
function checkN(address module, address[] calldata attesters, uint256 threshold) external view returns (uint256[] memory attestedAtArray);
```

