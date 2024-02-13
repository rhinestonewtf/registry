// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { SignedAttestation } from "./core/SignedAttestation.sol";
import { IRegistry } from "./IRegistry.sol";
/**
 * @author zeroknots
 */

contract Registry is IRegistry, SignedAttestation { }
