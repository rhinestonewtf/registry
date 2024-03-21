// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import { SignedAttestation } from "./core/SignedAttestation.sol";
import { IRegistry } from "./IRegistry.sol";

/**
 * ## Overview
 *
 * Account abstraction (or smart accounts) will deliver three key enhancements for the Ethereum ecosystem:
 * improved UX, enhanced user security and greater wallet extensibility. Modular smart accounts are the next
 * frontier for achieving these goals. However, it also opens up a number of new challenges that
 * could drastically undermine the objective by opening up a plethora of new attack vectors and security concerns for accounts.
 *
 * The Registry aims to solve this concern by providing a means of verifying the legitimacy and
 * security of independently built smart account modules for installation and use across any integrated
 * smart account. It allows entities to attest to statements about modules and smart accounts to query these
 *  at module installation and/or execution time. The Registry is a Singleton that is free, open and
 *  permissionless. It also serves as the reference implementation
 *  for [ERC-7484](https://eips.ethereum.org/EIPS/eip-7484).
 * ## Core Concepts
 * ### Attestations
 * Attestations on the Registry represent statements about Modules. An Attestation is made using a
 *  particular [Schema](./Schemas.md) that is used to encode and decode the Attestation data. The
 *  most important usecase for Attestations is to make statements about the security of a Module.
 *
 * An attestation consists of two primary elements: the Schema and the
 * Attestation data. The Schema acts as a standardized structure for
 * creating and validating Attestations, defining how the Attestation data is encoded and decoded.
 *
 * ### Schemas
 *
 * [Schemas](./docs/Schema.md) represent predefined structures utilized for the formation and
 * verification of Attestation data. Using flexible Schemas rather than a single, fixed Schema
 * allows Attesters to encode their data in a custom way, providing flexibility when creating
 * Attestations. For example, the data of an Attestation about the outcome of the formal
 * verification on a Module will have a very format than the data of an Attestation about what
 * interfaces a Module supports.
 *
 * ### Resolvers
 *
 * Resolvers are external contracts that are tied to Modules and called when specific Registry actions are executed. These actions are:
 * - attestation
 * - revocation
 * - module registration / deployment
 *
 * This architectural design aims to provide entities like Smart Account vendors or DAOs, with the
 * flexibility to incorporate custom business logic while maintaining the
 * robustness and security of the core functionalities implemented by the Registry
 *
 * ### Attesters
 * Attesters are individuals or organizations responsible for
 * creating and signing Attestations. They add the Attestation to the
 * Registry, making it available for verification.
 *
 * ### Modules
 * Modules are smart contracts that act as modular components that can be added to Smart Accounts.
 * The registry is agnostic towards Smart Account or Module implementations. Only Module addresses and
 * deployment metadata are stored on the registry.
 *
 * Modules are registered on the Registry either during, using `CREATE2`, `CREATE3`
 *  or a custom deployment factory, or after deployment.
 *
 * ## Architecture
 *
 * ![Sequence Diagram](https://raw.githubusercontent.com/rhinestonewtf/registry/main/public/docs/all.svg)
 *
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
