## Intro

Attestations are security guarantees or audit results that authorities commit to the registry.
these are the artifacts that smart account or users query when validating the safety of a module they want to use in their smart account.

![Attestation Flow](../public/docs/attestation.png)

## Specs

Attestations are made for a specific schema. the struct defines relevant metadata, while the attestation data is abi encoded in the data field.
the ABI for the attestation must follow the definition of the schema.
```solidity
struct Attestation {
    bytes32 uid; // A unique identifier of the attestation.
    bytes32 schema; // The unique identifier of the schema.
    uint64 time; // The time when the attestation was created (Unix timestamp).
    uint64 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint64 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    bytes32 refUID; // The UID of the related attestation.
    address recipient; // The recipient of the attestation.
    address attester; // The attester/sender of the attestation.
    bool revocable; // Whether the attestation is revocable.
    bytes data; // Custom attestation data.
}
```

### chaining of attestation

to allow for complex attestation verifiction models, attestors may utilize the redUID field that references another already existing attestation UID 
Chaining of attestations can allow for complex trust delegation models.


### Attestation Incentives
- Monetization can be implemented in Resolvers

## Verifiction of Attestations
the registry exposes a function that allows smart accounts or end users to query security attestations for a selected module.
this functionality can be called during module installation or execution.

## Challenges

different smart accounts will have different querying needs:
- threshold of n/m authorities
- chained attestations
- revert vs return false





