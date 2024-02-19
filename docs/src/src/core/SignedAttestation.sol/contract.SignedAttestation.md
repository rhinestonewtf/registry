# SignedAttestation
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/SignedAttestation.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md), [Attestation](/src/core/Attestation.sol/abstract.Attestation.md), EIP712


## State Variables
### attesterNonce

```solidity
mapping(address attester => uint256 nonce) public attesterNonce;
```


## Functions
### attest

Allows msg.sender to attest to multiple modules' security status.
The AttestationRequest.Data provided should match the attestation
schema defined by the Schema corresponding to the SchemaUID

*This function will revert if the same module is attested twice by the same attester.
If you want to re-attest, you have to revoke your attestation first, and then attest again.*


```solidity
function attest(SchemaUID schemaUID, address attester, AttestationRequest calldata request, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schemaUID`|`SchemaUID`|The SchemaUID of the schema the attestation is based on.|
|`attester`|`address`||
|`request`|`AttestationRequest`|a single AttestationRequest|
|`signature`|`bytes`||


### attest

Allows msg.sender to attest to multiple modules' security status.
The AttestationRequest.Data provided should match the attestation
schema defined by the Schema corresponding to the SchemaUID

*This function will revert if the same module is attested twice by the same attester.
If you want to re-attest, you have to revoke your attestation first, and then attest again.*


```solidity
function attest(SchemaUID schemaUID, address attester, AttestationRequest[] calldata requests, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schemaUID`|`SchemaUID`|The SchemaUID of the schema the attestation is based on.|
|`attester`|`address`||
|`requests`|`AttestationRequest[]`||
|`signature`|`bytes`||


### revoke

Allows msg.sender to revoke an attstation made by the same msg.sender

*this function will revert if the attestation is not found*


```solidity
function revoke(address attester, RevocationRequest calldata request, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attester`|`address`||
|`request`|`RevocationRequest`| the RevocationRequest|
|`signature`|`bytes`||


### revoke

Allows msg.sender to revoke an attstation made by the same msg.sender

*this function will revert if the attestation is not found*


```solidity
function revoke(address attester, RevocationRequest[] calldata requests, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attester`|`address`||
|`requests`|`RevocationRequest[]`||
|`signature`|`bytes`||


### _domainNameAndVersion

override thats used by Solady's EIP712 cache (constructor)


```solidity
function _domainNameAndVersion() internal view virtual override returns (string memory name, string memory version);
```

### getDigest


```solidity
function getDigest(AttestationRequest calldata request, address attester) external view returns (bytes32 digest);
```

### getDigest


```solidity
function getDigest(AttestationRequest[] calldata requests, address attester) external view returns (bytes32 digest);
```

### getDigest


```solidity
function getDigest(RevocationRequest calldata request, address attester) external view returns (bytes32 digest);
```

### getDigest


```solidity
function getDigest(RevocationRequest[] calldata requests, address attester) external view returns (bytes32 digest);
```

