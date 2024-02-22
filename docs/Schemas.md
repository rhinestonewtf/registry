## Intro

Attestations on the registry are `abi.encoded` bytes. To allow frontends or other integrations to decode the attestations,
the Registry uses Schema definition strings.

## Specs

A Schema can hold a string encoded ABI describtion that defines the data fields for Attestations done against this schema.

```solidity
struct SchemaRecord {
    uint48 registeredAt; // The time when the schema was registered (Unix timestamp).
    IExternalSchemaValidator validator; // Optional external schema validator.
    string schema; // Custom specification of the schema (e.g., an ABI).
}
```

### IExternalSchemaValidator

As an optional feasture to the registry, an `IExternalSchemaValidator`
can be provided to `abi.decode` all or parts of attestations made against the schema.

The implementation of this Validator is up to the Schema validators discression.

```solidity
interface IExternalSchemaValidator is IERC165 {
    function validateSchema(AttestationRequest calldata attestation)
        external
        view
        returns (bool);
    function validateSchema(AttestationRequest[] calldata attestations)
        external
        view
        returns (bool);
}
```
