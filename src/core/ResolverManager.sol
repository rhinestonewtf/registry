// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ResolverRecord, ResolverUID } from "../DataTypes.sol";
import { ZERO_ADDRESS } from "../Common.sol";
import { IExternalResolver } from "../external/IExternalResolver.sol";
import { UIDLib } from "../lib/Helpers.sol";
import { IRegistry } from "../IRegistry.sol";

abstract contract ResolverManager is IRegistry {
    using UIDLib for ResolverRecord;

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

    modifier onlyResolver(IExternalResolver resolver) {
        if (
            address(resolver) == address(0)
                || !resolver.supportsInterface(type(IExternalResolver).interfaceId)
        ) {
            revert InvalidResolver(resolver);
        }
        _;
    }

    function registerResolver(IExternalResolver _resolver)
        external
        onlyResolver(_resolver)
        returns (ResolverUID uid)
    {
        // build a ResolverRecord from the input
        ResolverRecord memory resolver =
            ResolverRecord({ resolver: _resolver, resolverOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        uid = resolver.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address(resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert ResolverAlreadyExists();
        }

        // Storing schema in the _schemas mapping
        resolvers[uid] = resolver;

        emit NewResolver(uid, address(_resolver));
    }

    function setResolver(
        ResolverUID uid,
        IExternalResolver resolver
    )
        external
        onlyResolver(resolver)
        onlyResolverOwner(uid)
    {
        ResolverRecord storage referrer = resolvers[uid];
        referrer.resolver = resolver;
        emit NewResolver(uid, address(resolver));
    }
}
