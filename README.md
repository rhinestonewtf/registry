<img align="right" width="150" height="150" top="100" src="./public/logo.png">

# Registry [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) ![solidity](https://img.shields.io/badge/solidity-^0.8.22-lightgrey) [![Foundry][foundry-badge]][foundry]

[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

This Contract is in active development. Do not use this in Prod!

## Overview

Account abstraction (or smart accounts) will deliver three key enhancements for the Ethereum ecosystem:
improved UX, enhanced user security and greater wallet extensibility. Modular smart accounts are the next
frontier for achieving these goals. However, it also opens up a number of new challenges that
could drastically undermine the objective by opening up a plethora of new attack vectors and security concerns for accounts.

The Registry aims to solve this concern by providing a means of verifying the legitimacy and
security of independently built smart account modules for installation and use across any integrated
smart account. It allows entities to attest to statements about modules and smart accounts to query these at module nstallation and/or execution time. The Registry is a Singleton that is free, open and permissionless. It also serves as the reference implementation for [ERC-7484](https://eips.ethereum.org/EIPS/eip-7484).

## Core Concepts

### Attestations

Attestations on the Registry represent statements about Modules. An Attestation is made using a particular [Schema](./Schemas.md) that is used to encode and decode the Attestation data. The most important usecase for Attestations is to make statements about the security of a Module.

An attestation consists of two primary elements: the Schema and the
Attestation data. The Schema acts as a standardized structure for
creating and validating Attestations, defining how the Attestation data is encoded and decoded.

### Schemas

[Schemas](./docs/Schema.md) represent predefined structures utilized for the formation and
verification of Attestation data. Using flexible Schemas rather than a single, fixed Schema allows Attesters to encode their data in a custom way, providing flexibility when creating Attestations. For example, the data of an Attestation about the outcome of the formal verification on a Module will have a very format than the data of an Attestation about what interfaces a Module supports.

### Resolvers

Resolvers are external contracts that are tied to Modules and called when specific Registry actions are executed. These actions are:

- attestation
- revocation
- module registration / deployment

This architectural design aims to provide entities like Smart Account vendors or DAOs, with the
flexibility to incorporate custom business logic while maintaining the
robustness and security of the core functionalities implemented by the Registry

### Attesters

Attesters are individuals or organizations responsible for
creating and signing Attestations. They add the Attestation to the
Registry, making it available for verification.

### Modules

Modules are smart contracts that act as modular components that can be added to Smart Accounts.
The registry is agnostic towards Smart Account or Module implementations. Only Module addresses and
deployment metadata are stored on the registry.

Modules are registered on the Registry either during, using `CREATE2`, `CREATE3` or a custom deployment factory, or after deployment.

## Architecture

![Sequence Diagram](./public/docs/all.svg)

## Gas comparison

The following is a table of the gas differences between the Registry and a minimal [ERC-7484](https://eips.ethereum.org/EIPS/eip-7484) registry that only has one attester. As you can see, the gas difference is negligible for 1 or 2 attesters, but the Registry scales much better than using multiple single attester registries.

To run the tests yourself, run `forge test --mc RegistryGasComparisonTest -vv`.

| Attesters | Registry | Minimal7484Registry |
| --------- | -------- | ------------------- |
| 1         | 7983     | 7706                |
| 2         | 15472    | 15418               |
| 3         | 20823    | 23124               |
| n         | 5351n    | 7706n               |

## Deployments

Current address: [0x500684cBaa280aDf80d5ACf7A32Daebb23162e63](https://blockscan.com/address/0x500684cBaa280aDf80d5ACf7A32Daebb23162e63)

## Contribute

For feature or change requests, feel free to open a PR or get in touch with us.

## Credits & Special Thanks

For the continious support and constructive feedback, we would like to thank:

- [Ethereum Foundation](https://erc4337.mirror.xyz/hRn_41cef8oKn44ZncN9pXvY3VID6LZOtpLlktXYtmA)
- ERC-4337 Team
- Richard Meissner (Safe) @rimeissner
- Taek @taek.eth
- Biconomy
- Heavily inspired by EAS

## Authors ✨

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="http://twitter.com/zeroknotsETH/"><img src="https://pbs.twimg.com/profile_images/1639062011387715590/bNmZ5Gpf_400x400.jpg" width="100px;" alt=""/><br /><sub><b>zeroknots</b></sub></a><br /><a href="https://github.com/rhinestonewtf/registry/commits?author=zeroknots" title="Code">💻</a></td>
    <td align="center"><a href="https://twitter.com/abstractooor"><img src="https://avatars.githubusercontent.com/u/26718079" width="100px;" alt=""/><br /><sub><b>Konrad</b></sub></a><br /><a href="https://github.com/rhinestonewtf/registry/commits?author=kopy-kat" title="Code">💻</a> </td>
    
  </tr>
</table>
