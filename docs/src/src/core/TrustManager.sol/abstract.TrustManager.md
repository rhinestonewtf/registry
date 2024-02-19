# TrustManager
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/TrustManager.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md), [TrustManagerExternalAttesterList](/src/core/TrustManagerExternalAttesterList.sol/abstract.TrustManagerExternalAttesterList.md)

**Author:**
rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
Implements EIP-7484 to query attestations stored in the registry.

*This contract is abstract and provides utility functions to query attestations.*


## State Variables
### $accountToAttester

```solidity
mapping(address account => TrustedAttesterRecord attesters) internal $accountToAttester;
```


## Functions
### trustAttesters

Allows smartaccounts - the end users of the registry - to appoint
one or many attesters as trusted.


```solidity
function trustAttesters(uint8 threshold, address[] memory attesters) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`threshold`|`uint8`|The minimum number of attestations required for a module to be considered secure.|
|`attesters`|`address[]`|The addresses of the attesters to be trusted.|


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

### _check

Internal helper function to check for module's security attestations on behalf of a SmartAccount
will use registy's storage to get the trusted attester(s) of a smart account, and check if the module was attested


```solidity
function _check(address smartAccount, address module, ModuleType moduleType) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`smartAccount`|`address`|the smart account to check for|
|`module`|`address`|address of the module to check|
|`moduleType`|`ModuleType`|(optional param), setting  moduleType = 0, will ignore moduleTypes in attestations|


### _requireValidAttestation

Check that attestationRecord is valid:
- not revoked
- not expired
- correct module type (if not ZERO_MODULE_TYPE)

this function reverts if the attestationRecord is not valid


```solidity
function _requireValidAttestation(ModuleType expectedType, AttestationRecord storage $attestation) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`expectedType`|`ModuleType`|the expected module type. if this is ZERO_MODULE_TYPE, types specified in the attestation are ignored|
|`$attestation`|`AttestationRecord`|the storage reference of the attestation record to check|


### findTrustedAttesters

Get trusted attester for a specific smartAccount


```solidity
function findTrustedAttesters(address smartAccount) public view returns (address[] memory attesters);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`smartAccount`|`address`|The address of the smartAccount|


