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

### Registration of Schemas across L2s

The schemaUID is generated using the schema definition as well as the schemaOwner (sender of the schema registration request)
it is important that these parameters are reused across chains to ensure that attestations propagated across chains are compatible

```solidity
function _getUID(SchemaRecord memory schemaRecord) private pure returns (bytes32) {
    return keccak256(
        abi.encodePacked(schemaRecord.schema, schemaRecord.schemaOwner, schemaRecord.revocable)
    );
}
```
