# IRegistry
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/IRegistry.sol)

**Inherits:**
[IERC7484](/src/IRegistry.sol/interface.IERC7484.md)


## Functions
### trustAttesters

Allows smartaccounts - the end users of the registry - to appoint
one or many attesters as trusted.

this function reverts, if address(0), or duplicates are provided in attesters[]


```solidity
function trustAttesters(uint8 threshold, address[] calldata attesters) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`threshold`|`uint8`|The minimum number of attestations required for a module to be considered secure.|
|`attesters`|`address[]`|The addresses of the attesters to be trusted.|


### findTrustedAttesters

Get trusted attester for a specific smartAccount


```solidity
function findTrustedAttesters(address smartAccount) external view returns (address[] memory attesters);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`smartAccount`|`address`|The address of the smartAccount|


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
|`requests`|`AttestationRequest[]`|An array of AttestationRequest|


### attest

Allows attester to attest by signing an AttestationRequest (ECDSA or ERC1271)
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
|`attester`|`address`|The address of the attester|
|`request`|`AttestationRequest`|An AttestationRequest|
|`signature`|`bytes`|The signature of the attester. ECDSA or ERC1271|


### attest

Allows attester to attest by signing an AttestationRequest (ECDSA or ERC1271)
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
|`attester`|`address`|The address of the attester|
|`requests`|`AttestationRequest[]`|An array of AttestationRequest|
|`signature`|`bytes`|The signature of the attester. ECDSA or ERC1271|


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

### revoke

Allows msg.sender to revoke an attstation made by the same msg.sender

*this function will revert if the attestation is not found*

*this function will revert if the attestation is already revoked*


```solidity
function revoke(RevocationRequest calldata request) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`request`|`RevocationRequest`| the RevocationRequest|


### revoke

Allows msg.sender to revoke multiple attstations made by the same msg.sender

*this function will revert if the attestation is not found*

*this function will revert if the attestation is already revoked*


```solidity
function revoke(RevocationRequest[] calldata requests) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`requests`|`RevocationRequest[]`|the RevocationRequests|


### revoke

Allows attester to revoke an attestation by signing an RevocationRequest (ECDSA or ERC1271)


```solidity
function revoke(address attester, RevocationRequest calldata request, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attester`|`address`|the signer / revoker|
|`request`|`RevocationRequest`|the RevocationRequest|
|`signature`|`bytes`|ECDSA or ERC1271 signature|


### revoke

Allows attester to revoke an attestation by signing an RevocationRequest (ECDSA or ERC1271)

*if you want to revoke multiple attestations, but from different attesters, call this function multiple times*


```solidity
function revoke(address attester, RevocationRequest[] calldata requests, bytes calldata signature) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`attester`|`address`|the signer / revoker|
|`requests`|`RevocationRequest[]`|array of RevocationRequests|
|`signature`|`bytes`|ECDSA or ERC1271 signature|


### deployModule

This registry implements a CREATE2 factory, that allows module developers to register and deploy module bytecode


```solidity
function deployModule(
    bytes32 salt,
    ResolverUID resolverUID,
    bytes calldata initCode,
    bytes calldata metadata
)
    external
    payable
    returns (address moduleAddr);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`salt`|`bytes32`|The salt to be used in the CREATE2 factory. This adheres to Pr000xy/Create2Factory.sol salt formatting. The salt's first bytes20 should be the address of the sender or bytes20(0) to bypass the check (this will lose replay protection)|
|`resolverUID`|`ResolverUID`|The resolverUID to be used in the CREATE2 factory|
|`initCode`|`bytes`|The initCode to be used in the CREATE2 factory|
|`metadata`|`bytes`|The metadata to be stored on the registry. This field is optional, and might be used by the module developer to store additional information about the module or facilitate business logic with the Resolver stub|


### deployViaFactory

Registry can use other factories to deploy the module

This function is used to deploy and register a module using a factory contract.
Since one of the parameters of this function is a unique resolverUID and any
registered module address can only be registered once,
using this function is of risk for a frontrun attack


```solidity
function deployViaFactory(
    address factory,
    bytes calldata callOnFactory,
    bytes calldata metadata,
    ResolverUID resolverUID
)
    external
    payable
    returns (address moduleAddress);
```

### registerModule

Already deployed module addresses can be registered on the registry

This function is used to deploy and register an already deployed module.
Since one of the parameters of this function is a unique resolverUID and any
registered module address can only be registered once,
using this function is of risk for a frontrun attack


```solidity
function registerModule(ResolverUID resolverUID, address moduleAddress, bytes calldata metadata) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`resolverUID`|`ResolverUID`|The resolverUID to be used for the module|
|`moduleAddress`|`address`|The address of the module to be registered|
|`metadata`|`bytes`|The metadata to be stored on the registry. This field is optional, and might be used by the module developer to store additional information about the module or facilitate business logic with the Resolver stub|


### calcModuleAddress

in conjunction with the deployModule() function, this function let's you
predict the address of a CREATE2 module deployment


```solidity
function calcModuleAddress(bytes32 salt, bytes calldata initCode) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`salt`|`bytes32`|CREATE2 salt|
|`initCode`|`bytes`|module initcode|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|moduleAddress counterfactual address of the module deployment|


### findModule

Getter function to get the stored ModuleRecord for a specific module address.


```solidity
function findModule(address moduleAddress) external view returns (ModuleRecord memory moduleRecord);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleAddress`|`address`|The address of the module|


### registerSchema

Register Schema and (optional) external IExternalSchemaValidator
Schemas describe the structure of the data of attestations
every attestation made on this registry, will reference a SchemaUID to
make it possible to decode attestation data in human readable form
overrwriting a schema is not allowed, and will revert


```solidity
function registerSchema(string calldata schema, IExternalSchemaValidator validator) external returns (SchemaUID uid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`schema`|`string`|ABI schema used to encode attestations that are made with this schema|
|`validator`|`IExternalSchemaValidator`|(optional) external schema validator that will be used to validate attestations. use address(0), if you dont need an external validator|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`SchemaUID`|SchemaUID of the registered schema|


### findSchema

getter function to retrieve SchemaRecord


```solidity
function findSchema(SchemaUID uid) external view returns (SchemaRecord memory record);
```

### registerResolver

Allows Marketplace Agents to register external resolvers.


```solidity
function registerResolver(IExternalResolver resolver) external returns (ResolverUID uid);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`resolver`|`IExternalResolver`|external resolver contract|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|ResolverUID of the registered resolver|


### setResolver

Entities that previously regsitered an external resolver, may update the implementation address.


```solidity
function setResolver(ResolverUID uid, IExternalResolver resolver) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|The UID of the resolver.|
|`resolver`|`IExternalResolver`|The new resolver implementation address.|


### transferResolverOwnership

Transfer ownership of resolverUID to a new address


```solidity
function transferResolverOwnership(ResolverUID uid, address newOwner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|The UID of the resolver to transfer ownership for|
|`newOwner`|`address`|The address of the new owner|


### findResolver

Getter function to get the ResolverRecord of a registerd resolver


```solidity
function findResolver(ResolverUID uid) external view returns (ResolverRecord memory record);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uid`|`ResolverUID`|The UID of the resolver.|


## Events
### NewTrustedAttesters

```solidity
event NewTrustedAttesters();
```

### Revoked

```solidity
event Revoked(address indexed moduleAddr, address indexed revoker, SchemaUID schema);
```

### Attested

```solidity
event Attested(address indexed moduleAddr, address indexed attester, SchemaUID schemaUID, AttestationDataRef indexed sstore2Pointer);
```

### ModuleRegistration

```solidity
event ModuleRegistration(address indexed implementation, ResolverUID resolverUID, bool deployedViaRegistry);
```

### SchemaRegistered

```solidity
event SchemaRegistered(SchemaUID indexed uid, address indexed registerer);
```

### NewResolver

```solidity
event NewResolver(ResolverUID indexed uid, address indexed resolver);
```

### NewResolverOwner

```solidity
event NewResolverOwner(ResolverUID indexed uid, address newOwner);
```

## Errors
### InvalidResolver

```solidity
error InvalidResolver(IExternalResolver resolver);
```

### InvalidResolverUID

```solidity
error InvalidResolverUID(ResolverUID uid);
```

### InvalidTrustedAttesterInput

```solidity
error InvalidTrustedAttesterInput();
```

### NoTrustedAttestersFound

```solidity
error NoTrustedAttestersFound();
```

### RevokedAttestation

```solidity
error RevokedAttestation(address attester);
```

### InvalidModuleType

```solidity
error InvalidModuleType();
```

### AttestationNotFound

```solidity
error AttestationNotFound();
```

### InsufficientAttestations

```solidity
error InsufficientAttestations();
```

### AlreadyRevoked

```solidity
error AlreadyRevoked();
```

### ModuleNotFoundInRegistry

```solidity
error ModuleNotFoundInRegistry(address module);
```

### AccessDenied

```solidity
error AccessDenied();
```

### InvalidAttestation

```solidity
error InvalidAttestation();
```

### InvalidExpirationTime

```solidity
error InvalidExpirationTime();
```

### DifferentResolvers

```solidity
error DifferentResolvers();
```

### InvalidSignature

```solidity
error InvalidSignature();
```

### InvalidModuleTypes

```solidity
error InvalidModuleTypes();
```

### AlreadyRegistered

```solidity
error AlreadyRegistered(address module);
```

### InvalidDeployment

```solidity
error InvalidDeployment();
```

### ModuleAddressIsNotContract

```solidity
error ModuleAddressIsNotContract(address moduleAddress);
```

### FactoryCallFailed

```solidity
error FactoryCallFailed(address factory);
```

### SchemaAlreadyExists

```solidity
error SchemaAlreadyExists(SchemaUID uid);
```

### InvalidSchema

```solidity
error InvalidSchema();
```

### InvalidSchemaValidator

```solidity
error InvalidSchemaValidator(IExternalSchemaValidator validator);
```

### ResolverAlreadyExists

```solidity
error ResolverAlreadyExists();
```

### ExternalError_SchemaValidation

```solidity
error ExternalError_SchemaValidation();
```

### ExternalError_ResolveAtteststation

```solidity
error ExternalError_ResolveAtteststation();
```

### ExternalError_ResolveRevocation

```solidity
error ExternalError_ResolveRevocation();
```

### ExternalError_ModuleRegistration

```solidity
error ExternalError_ModuleRegistration();
```

