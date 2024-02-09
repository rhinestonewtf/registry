// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ResolverRecord, ResolverUID } from "../DataTypes.sol";
import { EMPTY_RESOLVER_UID, ZERO_ADDRESS } from "../Common.sol";
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

    modifier notZero(ResolverUID uid) {
        if (uid == EMPTY_RESOLVER_UID) {
            revert InvalidResolverUID(uid);
        }
        _;
    }

    /**
     * If a resolver is not address(0), we check if it supports the IExternalResolver interface
     */
    modifier onlyResolver(IExternalResolver resolver) {
        if (
            address(resolver) == address(0)
                || !resolver.supportsInterface(type(IExternalResolver).interfaceId)
        ) {
            revert InvalidResolver(resolver);
        }
        _;
    }

    function registerResolver(IExternalResolver resolver)
        external
        onlyResolver(resolver)
        returns (ResolverUID uid)
    {
        // build a ResolverRecord from the input
        ResolverRecord memory resolverRecord =
            ResolverRecord({ resolver: resolver, resolverOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        uid = resolverRecord.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address(resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert ResolverAlreadyExists();
        }

        // SSTORE schema in the resolvers mapping
        resolvers[uid] = resolverRecord;

        emit NewResolver(uid, address(resolver));
    }

    // TODO: VULN:
    // Attacker could register the same resolver, thus be the owner of the resolverUID,
    // then set the resolver to a malicious contract
    function setResolver(
        ResolverUID uid,
        IExternalResolver resolver
    )
        external
        onlyResolver(resolver)
        onlyResolverOwner(uid) // authorization control
    {
        ResolverRecord storage referrer = resolvers[uid];
        referrer.resolver = resolver;
        emit NewResolver(uid, address(resolver));
    }
}
