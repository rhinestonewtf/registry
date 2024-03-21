// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { ResolverRecord, ResolverUID } from "../DataTypes.sol";
import { ZERO_ADDRESS } from "../Common.sol";
import { IExternalResolver } from "../external/IExternalResolver.sol";
import { UIDLib } from "../lib/Helpers.sol";
import { IRegistry } from "../IRegistry.sol";

/**
 * Resolvers are external contracts that are tied to Modules and called when specific Registry actions are executed.
 * ## Resolver Hooks
 *
 * external Resolvers are called during:
 *
 * - attestation
 * - revocation
 * - module registration
 *
 * This architectural design aims to provide entities like Smart Account vendors or DAOs, with the
 * flexibility to incorporate custom business logic while maintaining the
 * robustness and security of the core functionalities implemented by the Registry.
 *
 * ## Role of Resolvers in extending Registry functionalities
 *
 * Entities utilizing the Registry frequently need to extend its core functionalities
 * to cater to their unique business requirements. Resolvers are the mechanisms that
 * make this possible, allowing for:
 *
 * - _Custom Business Logic Integration:_ Entities can build upon the foundational
 *   registry operations by introducing complex logic sequences, tailored to their
 *   operational needs.
 *
 * - _Security Assurance:_ One of the significant advantages of using resolvers is that
 *   they abstract away the intricacies of attestation storage and validation.
 *   This abstraction ensures that the foundational security of the Registry isn't compromised,
 *   even when new functionalities are added.
 *
 * - _Cost Efficiency in Audits:_ Given that the core attestation storage and validation
 *   logic remains untouched, auditing becomes more straightforward and cost-effective.
 *   Entities can focus their audit efforts on their custom logic without the need to
 *   re-audit the underlying core systems.
 *
 * ## The `IExternalResolver` interface: Standardizing Resolvers
 *
 * For any entity looking to employ a resolver, adherence to a standardized
 * interface is essential.
 * The [IExternalResolver interface](../../external/IExternalResolver.sol/interface.IExternalResolver.html) delineates the essential
 * functions a resolver must implement to ensure seamless integration and operation with the Registry.
 * @dev only `msg.sender` and the external `IExternalResolver` address are used to create a unique ID for the resolver
 *    This allows for a single resolver address to be possible across different chains
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract ResolverManager is IRegistry {
    using UIDLib for ResolverRecord;

    mapping(ResolverUID uid => ResolverRecord resolver) internal $resolvers;

    /**
     * @dev Modifier to require that the caller is the owner of a resolver
     *
     * @param uid The UID of the resolver.
     */
    modifier onlyResolverOwner(ResolverUID uid) {
        if ($resolvers[uid].resolverOwner != msg.sender) {
            revert AccessDenied();
        }
        _;
    }

    /**
     * If a resolver is not address(0), we check if it supports the `IExternalResolver` interface
     */
    modifier onlyResolver(IExternalResolver resolver) {
        if (address(resolver) == address(0) || !resolver.supportsInterface(type(IExternalResolver).interfaceId)) {
            revert InvalidResolver(resolver);
        }
        _;
    }

    /**
     * @inheritdoc IRegistry
     */
    function registerResolver(IExternalResolver resolver) external onlyResolver(resolver) returns (ResolverUID uid) {
        // build a ResolverRecord from the input
        ResolverRecord memory resolverRecord = ResolverRecord({ resolver: resolver, resolverOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        uid = resolverRecord.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address($resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert ResolverAlreadyExists();
        }

        // SSTORE schema in the resolvers mapping
        $resolvers[uid] = resolverRecord;

        emit NewResolver(uid, address(resolver));
    }

    /**
     * @inheritdoc IRegistry
     */
    function setResolver(
        ResolverUID uid,
        IExternalResolver resolver
    )
        external
        onlyResolver(resolver)
        onlyResolverOwner(uid) // authorization control
    {
        ResolverRecord storage referrer = $resolvers[uid];
        referrer.resolver = resolver;
        emit NewResolver(uid, address(resolver));
    }

    /**
     * @inheritdoc IRegistry
     */
    function transferResolverOwnership(ResolverUID uid, address newOwner) external onlyResolverOwner(uid) {
        $resolvers[uid].resolverOwner = newOwner;
        emit NewResolverOwner(uid, newOwner);
    }

    /**
     * @inheritdoc IRegistry
     */
    function findResolver(ResolverUID uid) external view returns (ResolverRecord memory) {
        return $resolvers[uid];
    }
}
