# ModuleDeploymentLib
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/lib/ModuleDeploymentLib.sol)

**Author:**
zeroknots

*A library that can be used to deploy the Registry*


## Functions
### containsCaller


```solidity
modifier containsCaller(bytes32 salt);
```

### deploy


```solidity
function deploy(bytes calldata _initCode, bytes32 salt) internal containsCaller(salt) returns (address deploymentAddress);
```

### calcAddress

Calculates the deterministic address of a contract that would be deployed using the CREATE2 opcode.

*The calculated address is based on the contract's code, a salt, and the address of the current contract.*

*This function uses the formula specified in EIP-1014 (https://eips.ethereum.org/EIPS/eip-1014).*


```solidity
function calcAddress(bytes calldata initCode, bytes32 salt) internal view returns (address targetDeploymentAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initCode`|`bytes`|The contract code that would be deployed.|
|`salt`|`bytes32`|A salt used for the address calculation. This must be the same salt that would be passed to the CREATE2 opcode.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`targetDeploymentAddress`|`address`|The address that the contract would be deployed at if the CREATE2 opcode was called with the specified _code and _salt.|


## Errors
### InvalidSalt

```solidity
error InvalidSalt();
```

### InvalidAddress

```solidity
error InvalidAddress();
```

### InvalidDeployment

```solidity
error InvalidDeployment();
```

