# Resolvers

Resolvers are external contracts that are tied to Modules and called when specific Registry actions are executed.

## Hooks

Resolvers are called during:

- attestation,
- revocation and
- module registration.

This architectural design aims to provide entities like Smart Account vendors or DAOs, with the
flexibility to incorporate custom business logic while maintaining the
robustness and security of the core functionalities implemented by the Registry.

## Role of Resolveres in extending Registry functionalities

Entities utilizing the Registry frequently need to extend its core functionalities
to cater to their unique business requirements. Resolvers are the mechanisms that
make this possible, allowing for:

- _Custom Business Logic Integration:_ Entities can build upon the foundational
  registry operations by introducing complex logic sequences, tailored to their
  operational needs.

- _Security Assurance:_ One of the significant advantages of using resolvers is that
  they abstract away the intricacies of attestation storage and validation.
  This abstraction ensures that the foundational security of the Registry isn't compromised,
  even when new functionalities are added.

- _Cost Efficiency in Audits:_ Given that the core attestation storage and validation
  logic remains untouched, auditing becomes more straightforward and cost-effective.
  Entities can focus their audit efforts on their custom logic without the need to
  re-audit the underlying core systems.

## The IResolver interface: Standardizing Resolvers

For any entity looking to employ a resolver, adherence to a standardized
interface is essential. The [IResolver interface](../src/external/IResolver.sol) delineates the essential
functions a resolver must implement to ensure seamless integration and operation with the Registry.

## Example Resolvers and Custom Development

To kickstart the process for developers and entities, the repository holds several example
resolvers. These serve as templates, guiding developers on how resolvers can be crafted and
highlighting the potential of what can be achieved. By utilizing these example resolvers as a
base, developers can modify, enhance, and create Resolvers tailored to specific needs,
without needing to start from scratch.

- [Simple Resolver](../src/external/examples/SimpleValidator.sol)
- [Value Resolver](../src/external/examples/ValueResolver.sol)
- [Token Resolver](../src/external/examples/TokenizedResolver.sol)

## Adding a Resolver to the Registry

The Registry exposes the following functions to register and manage Resolvers:

```solidity
/**
 * @notice Registers a resolver and associates it with the caller.
 * @dev This function allows the registration of a resolver by computing a unique ID and associating it with the schema owner.
 *      Emits a SchemaResolverRegistered event upon successful registration.
 *
 * @param _resolver Address of the IResolver to be registered.
 *
 * @return uid The unique ID (ResolverUID) associated with the registered resolver.
 */

function registerResolver(IResolver _resolver) external returns (ResolverUID);

/**
 * @notice Updates the resolver for a given UID.
 *
 * @dev Can only be called by the owner of the schema.
 *
 * @param uid The UID of the schema to update.
 * @param resolver The new resolver interface.
 */
function setResolver(ResolverUID uid, IResolver resolver) external;
```

After storing the resolver on the registy, a ResolverUID is emited, that Module Developers can utilize to register Modules.

```solidity
struct ResolverRecord {
    IResolver resolver; // Optional schema resolver.
    address schemaOwner; // The address of the account used to register the schema.
}
```

## Sequence Diagram

![Schema](../public/docs/schema.svg)
