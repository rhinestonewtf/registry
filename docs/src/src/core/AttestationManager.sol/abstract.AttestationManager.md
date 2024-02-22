# AttestationManager
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/AttestationManager.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md), [ModuleManager](/src/core/ModuleManager.sol/abstract.ModuleManager.md), [SchemaManager](/src/core/SchemaManager.sol/abstract.SchemaManager.md), [TrustManager](/src/core/TrustManager.sol/abstract.TrustManager.md)

AttestationManager handles the registry's internal storage of new attestations and revocation of attestation

*This contract is abstract and provides utility functions to store attestations and revocations.*


## State Variables
### $moduleToAttesterToAttestations

```solidity
mapping(address module => mapping(address attester => AttestationRecord attestation)) internal $moduleToAttesterToAttestations;
```


## Functions
### _attest

Processes an attestation request and stores the attestation in the registry.
If the attestation was made for a module that was not registered, the function will revert.
function will get the external Schema Validator for the supplied SchemaUID
and call it, if an external IExternalSchemaValidator was set
function will get the external IExternalResolver for the module - that the attestation is for
and call it, if an external Resolver was set


```solidity
function _attest(address attester, SchemaUID schemaUID, AttestationRequest calldata request) internal;
```

### _attest

Processes an array of attestation requests  and stores the attestations in the registry.
If the attestation was made for a module that was not registered, the function will revert.
function will get the external Schema Validator for the supplied SchemaUID
and call it, if an external IExternalSchemaValidator was set
function will get the external IExternalResolver for the module - that the attestation is for
and call it, if an external Resolver was set


```solidity
function _attest(address attester, SchemaUID schemaUID, AttestationRequest[] calldata requests) internal;
```

### _storeAttestation

Stores an attestation in the registry storage.
The bytes encoded AttestationRequest.Data is not stored directly into the registry storage,
but rather stored with SSTORE2. SSTORE2/SLOAD2 is writing and reading contract storage
paying a fraction of the cost, it uses contract code as storage, writing data takes the
form of contract creations and reading data uses EXTCODECOPY.
since attestation data is supposed to be immutable, it is a good candidate for SSTORE2

*This function will revert if the same module is attested twice by the same attester.
If you want to re-attest, you have to revoke your attestation first, and then attest again.*


```solidity
function _storeAttestation(
    SchemaUID schemaUID,
    address attester,
    AttestationRequest calldata request
)
    internal
    returns (AttestationRecord memory record, ResolverUID resolverUID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schemaUID`|`SchemaUID`||
|`attester`|`address`|The address of the attesting account.|
|`request`|`AttestationRequest`|The AttestationRequest that was supplied via calldata|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`record`|`AttestationRecord`|The AttestationRecord of what was written into registry storage|
|`resolverUID`|`ResolverUID`|The resolverUID in charge for the module|


### _revoke

Revoke a single Revocation Request
This function will write the RevocationRequest into storage, and get the stored RevocationRecord back,
and pass the RevocationRecord to the resolver to check if the revocation is valid


```solidity
function _revoke(address attester, RevocationRequest calldata request) internal;
```

### _revoke

Revoke an array Revocation Request
This function will write the RevocationRequest into storage, and get the stored RevocationRecord back,
and pass the RevocationRecord to the resolver to check if the revocation is valid


```solidity
function _revoke(address attester, RevocationRequest[] calldata requests) internal;
```

### _storeRevocation

Gets the AttestationRecord for the supplied RevocationRequest and stores the revocation time in the registry storage


```solidity
function _storeRevocation(
    address revoker,
    RevocationRequest calldata request
)
    internal
    returns (AttestationRecord memory record, ResolverUID resolverUID);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`revoker`|`address`|The address of the attesting account.|
|`request`|`RevocationRequest`|The AttestationRequest that was supplied via calldata|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`record`|`AttestationRecord`|The AttestationRecord of what was written into registry storage|
|`resolverUID`|`ResolverUID`|The resolverUID in charge for the module|


### _getAttestation

Returns the attestation records for the given module and attesters.
This function is expected to be used by TrustManager and TrustManagerExternalAttesterList


```solidity
function _getAttestation(address module, address attester) internal view override returns (AttestationRecord storage $attestation);
```

