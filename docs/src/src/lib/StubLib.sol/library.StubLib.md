# StubLib
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/lib/StubLib.sol)

*A library that interacts with IExternalResolver and IExternalSchemaValidator*


## Functions
### requireExternalSchemaValidation

if Schema Validator is set, it will call validateSchema() on the validator


```solidity
function requireExternalSchemaValidation(AttestationRecord memory attestationRecord, SchemaRecord storage $schema) internal;
```

### requireExternalSchemaValidation


```solidity
function requireExternalSchemaValidation(AttestationRecord[] memory attestationRecords, SchemaRecord storage $schema) internal;
```

### requireExternalResolverOnAttestation


```solidity
function requireExternalResolverOnAttestation(AttestationRecord memory attestationRecord, ResolverRecord storage $resolver) internal;
```

### requireExternalResolverOnAttestation


```solidity
function requireExternalResolverOnAttestation(AttestationRecord[] memory attestationRecords, ResolverRecord storage $resolver) internal;
```

### tryExternalResolverOnRevocation


```solidity
function tryExternalResolverOnRevocation(
    AttestationRecord memory attestationRecord,
    ResolverRecord storage $resolver
)
    internal
    returns (bool resolved);
```

### tryExternalResolverOnRevocation


```solidity
function tryExternalResolverOnRevocation(
    AttestationRecord[] memory attestationRecords,
    ResolverRecord storage $resolver
)
    internal
    returns (bool resolved);
```

### requireExternalResolverOnModuleRegistration


```solidity
function requireExternalResolverOnModuleRegistration(
    ModuleRecord memory moduleRecord,
    address moduleAddress,
    ResolverRecord storage $resolver
)
    internal;
```

## Events
### ResolverRevocationError

```solidity
event ResolverRevocationError(IExternalResolver resolver);
```

