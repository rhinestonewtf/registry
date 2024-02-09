// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { IExternalResolver } from "../IExternalResolver.sol";
import { IRegistry } from "../../IRegistry.sol";
import "../../DataTypes.sol";

abstract contract ResolverBase is IExternalResolver {
    IRegistry internal immutable REGISTRY;

    constructor(IRegistry _registry) {
        REGISTRY = _registry;
    }

    modifier onlyRegistry() {
        require(msg.sender == address(REGISTRY), "ONLY_REGISTRY");
        _;
    }
}
