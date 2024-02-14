// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { IRegistry } from "./IRegistry.sol";
import { SignedAttestation } from "./core/SignedAttestation.sol";
/**
 * @author zeroknots
 */

contract Registry is IRegistry, SignedAttestation {
// TODO: should we create a default resolverUID thats address(0).
// this will allow the registry to be usable right after deployment without any resolver
}
