# IExternalResolver
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/external/IExternalResolver.sol)

**Inherits:**
IERC165

*The resolver is responsible for validating the schema and attestation data.*

*The resolver is also responsible for processing the attestation and revocation requests.*


## Functions
### resolveAttestation

*Processes an attestation and verifies whether it's valid.*


```solidity
function resolveAttestation(AttestationRecord calldata attestation) external payable returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attestation`|`AttestationRecord`|The new attestation.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the attestation is valid.|


### resolveAttestation


```solidity
function resolveAttestation(AttestationRecord[] calldata attestation) external payable returns (bool);
```

### resolveRevocation

*Processes an attestation revocation and verifies if it can be revoked.*


```solidity
function resolveRevocation(AttestationRecord calldata attestation) external payable returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attestation`|`AttestationRecord`|The existing attestation to be revoked.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the attestation can be revoked.|


### resolveRevocation


```solidity
function resolveRevocation(AttestationRecord[] calldata attestation) external payable returns (bool);
```

### resolveModuleRegistration

*Processes a Module Registration*


```solidity
function resolveModuleRegistration(address sender, address moduleAddress, ModuleRecord calldata record) external payable returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`address`|The msg.sender of the module registration|
|`moduleAddress`|`address`|address of the module|
|`record`|`ModuleRecord`|Module registration artefact|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the registration is valid|


