# Attestations

The Attestations function is responsible for creating attestations. Attestations are a representation of a statement or condition that has been verified to be true. In the [Registry], attestations are used to verify the validity, correctness, and security of smart account modules.

## Attestation Lifecycle

The life cycle of an attestation begins when an attester creates it. The attestation data, structured according to the schema provided by the SchemaResolver, is then added to the [Registry]. The attestation can also reference previous attestations using the refUID, creating a chain of trust.

During the attestation's life cycle, the [Registry] can invoke hooks on the SchemaResolver during specific events like attestation creation and revocation. This allows the SchemaResolver to ensure the integrity and correctness of the attestation throughout its life cycle.

Inputs:

Attestation data: This is the data that is being attested. The data is ABI-encoded according to the associated schema.
Outputs:

Attestation ID: A unique identifier for the attestation.

```solidity
struct Attestation {
    bytes32 uid; // A unique identifier of the attestation.
    bytes32 schema; // The unique identifier of the schema.
    bytes32 refUID; // The UID of the related attestation.
    address recipient; // The recipient of the attestation i.e. module
    address attester; // The attester/sender of the attestation.
    uint48 time; // The time when the attestation was created (Unix timestamp).
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint48 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    bool revocable; // Whether the attestation is revocable.
    bool propagateable; // Whether the attestation is propagateable to L2s.
    bytes data; // Custom attestation data.
}
```

### Building Trust

Attestations within the [Registry] play a fundamental role in endorsing the authenticity and security of smart account modules. In essence, attestations are digitally documented claims made by an entity about the security posture of an account abstraction module. Attestations provide a seal of authenticity for the associated data and serve as a testament to the module's security and legitimacy.

Each attestation have the option to reference other attestations using the refUID parameter, which enables them to reference other attestations, creating a chain of attestations or a "chain of trust". This interlinking of attestations offers a powerful way to track the lineage of security evaluations, modifications, or any other relevant events over the lifetime of a smart account module.

### Interactions with the SchemaResolver

Attestations are deeply integrated with the SchemaResolver. As entities make attestations, the registry calls hooks on the associated SchemaResolver, ensuring that the attestation data is correctly structured and verified against the schema. Or any other logic the SchemaResolver might elect to implement.

### The Revocation Process

In the event that an attester decides to revoke an attestation, they issue a revocation call to the [Registry]. Upon receiving this call, the registry updates the revocationTime field within the attestation record. This timestamp acts as a clear indication that the attestation has been revoked, and any trust or claims that stem from it should be reconsidered.

It's important to note that apart from the revocationTime, the rest of the attestation's metadata and data remains unchanged. This design choice is critical as it preserves the history of the attestation. Even if an attestation is revoked, its presence in the chain of trust is not erased. This allows for full transparency and traceability, which are key principles in the blockchain domain.

### Impact on Trust Chains

When an attestation is revoked, it can impact the validity of the entire chain of trust. Entities that rely on these attestations should take into account the revocationTime and reconsider the trust placed on subsequent attestations in the chain. This ensures that decisions are made based on the most relevant and accurate information.

### Interaction with the SchemaResolver

Upon an attestation's revocation, the [Registry] might call hooks on the associated SchemaResolver, allowing the SchemaResolver to update its internal state or perform other necessary actions. This maintains the consistency and accuracy of data across the registry.

### Editing Attestions

Attestations can not be edited. Should attestation data change, a new attestation needs to be made, and the old attestation must be revoked.

## Delegated Attestations

All attestations leveraged within the [Registry] are designated as "delegated".
Such attestations empower an entity to sign an attestation while enabling another entity to
bear the transaction cost. With these attestations, the actual attestant and the one shouldering the
transaction fee can be separate entities, thus accommodating a variety of use cases.
This becomes particularly beneficial when:

-   A service opts to cover its users' attestation costs (taking care of gas expenses)
-   An entity wishes to execute multiple attestations but allows the recipient or a different party to handle the transaction fees for blockchain integration.

```solidity
/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequestData {
    address recipient; // The recipient of the attestation.
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    bool revocable; // Whether the attestation is revocable.
    bool propagateable; // Whether the attestation is propagateable to L2s.
    bytes32 refUID; // The UID of the related attestation.
    bytes data; // Custom attestation data.
    uint256 value; // An explicit ETH amount to send to the resolver. This is important to prevent accidental user errors.
}


/**
 * @dev A struct representing the full arguments of the full delegated attestation request.
 */
struct DelegatedAttestationRequest {
    bytes32 schema; // The unique identifier of the schema.
    AttestationRequestData data; // The arguments of the attestation request.
    EIP712Signature signature; // The EIP712 signature data.
    address attester; // The attesting account.
}
```

### ERC1271 Support

The [Registry] attestation process supports the ERC1271 standard, which allows smart contracts to implement a standard interface for contract ownership. This is particularly useful for smart account modules that are owned by a smart contract. The [Registry] supports the ERC1271 standard for delegated attestations.
Should the attester in the DelegatedAttestationRequest be a contract, a ERC1271 validation call is made.

## Chained Attestations

The refUID is a unique identifier associated with each attestation. This identifier allows an attestation to reference other attestations, thereby establishing a chain of trust. This means that each attestation doesn't stand alone but is part of a larger, interconnected structure of trust.

When an attestation references another via its refUID, it inherently endorses the previous attestation's authenticity. This allows users and other parties to trace back through the chain of attestations, examining the history of endorsements for a particular smart account module.
