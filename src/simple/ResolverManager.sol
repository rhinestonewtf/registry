// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ResolverRecord, ResolverUID } from "../DataTypes.sol";

abstract contract ResolverManager {
    mapping(ResolverUID uid => ResolverRecord resolver) public resolvers;

    /**
     * @dev Modifier to require that the caller is the owner of a resolver
     *
     * @param uid The UID of the resolver.
     */
    modifier onlyResolverOwner(ResolverUID uid) {
        if (resolvers[uid].resolverOwner != msg.sender) {
            revert AccessDenied();
        }
        _;
    }

    /**
     * @inheritdoc IExternalResolver
     */
    function registerResolver(IResolver _resolver) external returns (ResolverUID uid) {
        if (address(_resolver) == ZERO_ADDRESS) revert InvalidResolver();

        // build a ResolverRecord from the input
        ResolverRecord memory resolver =
            ResolverRecord({ resolver: _resolver, resolverOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        uid = resolver.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address(resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert AlreadyExists();
        }

        // Storing schema in the _schemas mapping
        resolvers[uid] = resolver;

        emit SchemaResolverRegistered(uid, msg.sender);
    }

    /**
     * @inheritdoc IExternalResolver
     */
    function setResolver(ResolverUID uid, IResolver resolver) external onlyResolverOwner(uid) {
        ResolverRecord storage referrer = resolvers[uid];
        referrer.resolver = resolver;
        emit NewSchemaResolver(uid, address(resolver));
    }
}
