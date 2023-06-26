## Intro
Any module / plugin registered in the RSRegistry uses one schema.

![Schema Registration](../public/docs/schema.png)

## Challenges

Different authorities may chose d ifferent data points that are relevant for their ecosystem. 
To allow dynamic attetation data fields, we suggest to leverage an EAS-like schema registration system.

## Specs

Schema can hold a string encoded ABI describtion that defines the data fields for attestations done against this schema.

```solidty
struct SchemaRecord {
    bytes32 uid; // The unique identifier of the schema.
    ISchemaResolver resolver; // Optional schema resolver.
    bool revocable; // Whether the schema allows revocations explicitly.
    string schema; // Custom specification of the schema (e.g., an ABI).
}
```

### Resolvers / Schema owners
When registering a schema, a resolver contract can be specified. 
This contract exposes hooks that will be called during the attestation and revocation process.
The resolver may implement any logic to extend the attestation and revocation process.


