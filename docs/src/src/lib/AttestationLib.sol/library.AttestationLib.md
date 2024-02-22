# AttestationLib
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/lib/AttestationLib.sol)


## State Variables
### ATTEST_TYPEHASH

```solidity
bytes32 internal constant ATTEST_TYPEHASH = keccak256("AttestationRequest(address,uint48,bytes,uint256[])");
```


### REVOKE_TYPEHASH

```solidity
bytes32 internal constant REVOKE_TYPEHASH = keccak256("RevocationRequest(address)");
```


## Functions
### sload2


```solidity
function sload2(AttestationDataRef dataPointer) internal view returns (bytes memory data);
```

### sstore2


```solidity
function sstore2(AttestationRequest calldata request, bytes32 salt) internal returns (AttestationDataRef dataPointer);
```

### sstore2Salt

*We are using CREATE2 to deterministically generate the address of the attestation data.
Checking if an attestation pointer already exists, would cost more GAS in the average case.*


```solidity
function sstore2Salt(address attester, address module) internal view returns (bytes32 salt);
```

### hash


```solidity
function hash(AttestationRequest calldata data, uint256 nonce) internal pure returns (bytes32 _hash);
```

### hash


```solidity
function hash(AttestationRequest[] calldata data, uint256 nonce) internal pure returns (bytes32 _hash);
```

### hash


```solidity
function hash(RevocationRequest calldata data, uint256 nonce) internal pure returns (bytes32 _hash);
```

### hash


```solidity
function hash(RevocationRequest[] calldata data, uint256 nonce) internal pure returns (bytes32 _hash);
```

