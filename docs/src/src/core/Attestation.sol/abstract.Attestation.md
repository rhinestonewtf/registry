# Attestation
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/Attestation.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md), [AttestationManager](/src/core/AttestationManager.sol/abstract.AttestationManager.md)


## Functions
### attest

Allows msg.sender to attest to multiple modules' security status.
The AttestationRequest.Data provided should match the attestation
schema defined by the Schema corresponding to the SchemaUID

*This function will revert if the same module is attested twice by the same attester.
If you want to re-attest, you have to revoke your attestation first, and then attest again.*


```solidity
function attest(SchemaUID schemaUID, AttestationRequest calldata request) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schemaUID`|`SchemaUID`|The SchemaUID of the schema the attestation is based on.|
|`request`|`AttestationRequest`|a single AttestationRequest|


### attest

Allows msg.sender to attest to multiple modules' security status.
The AttestationRequest.Data provided should match the attestation
schema defined by the Schema corresponding to the SchemaUID

*This function will revert if the same module is attested twice by the same attester.
If you want to re-attest, you have to revoke your attestation first, and then attest again.*


```solidity
function attest(SchemaUID schemaUID, AttestationRequest[] calldata requests) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schemaUID`|`SchemaUID`|The SchemaUID of the schema the attestation is based on.|
|`requests`|`AttestationRequest[]`||


### revoke

Allows msg.sender to revoke an attstation made by the same msg.sender

*this function will revert if the attestation is not found*


```solidity
function revoke(RevocationRequest calldata request) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`request`|`RevocationRequest`| the RevocationRequest|


### revoke

Allows msg.sender to revoke an attstation made by the same msg.sender

*this function will revert if the attestation is not found*


```solidity
function revoke(RevocationRequest[] calldata requests) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requests`|`RevocationRequest[]`||


### findAttestation

Getter function to get AttestationRequest made by one attester


```solidity
function findAttestation(address module, address attester) external view returns (AttestationRecord memory attestation);
```

### findAttestations

Getter function to get AttestationRequest made by multiple attesters


```solidity
function findAttestations(address module, address[] calldata attesters) external view returns (AttestationRecord[] memory attestations);
```

