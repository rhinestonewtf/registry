## Intro

Attestations on the registry are `abi.encoded` bytes. To allow frontends or other integrations to decode the attestations,
the Registry uses Schema definition strings.

## Specs

A Schema can hold a string encoded ABI describtion that defines the data fields for Attestations done against this schema.

```solidity
struct SchemaRecord {
    uint48 registeredAt; // The time when the schema was registered (Unix timestamp).
    ISchemaValidator validator; // Optional external schema validator.
    string schema; // Custom specification of the schema (e.g., an ABI).
}
```

### ISchemaValidator

As an optional feasture to the registry, an `ISchemaValidator`
can be provided to `abi.decode` all or parts of attestations made against the schema.

The implementation of this Validator is up to the Schema validators discression.

```solidity
interface ISchemaValidator is IERC165 {
    function validateSchema(AttestationRequestData calldata attestation)
        external
        view
        returns (bool);
    function validateSchema(AttestationRequestData[] calldata attestations)
        external
        view
        returns (bool);
}
```
