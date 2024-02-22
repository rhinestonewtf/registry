// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { SignedAttestation } from "./core/SignedAttestation.sol";
import { IRegistry } from "./IRegistry.sol";

/**
 * Implementation of all features of the registry:
 *      - Register Schemas
 *      - Register External Resolvers
 *      - Register Modules
 *      - Make Attestations
 *      - Make Revocations
 *      - Delegate Trust to Attester(s)
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
contract Registry is IRegistry, SignedAttestation { }
