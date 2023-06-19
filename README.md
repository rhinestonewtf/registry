<img align="right" width="150" height="150" top="100" src="./public/readme.jpg">

# Rhinestone Registry • RSRegistry ![license](https://img.shields.io/github/license/rhinestonewtf/registry?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.17-lightgrey)

This Contract is in active development. Do not use this in Prod!


### Intro

RSRegistry allows developers to deploy modules / components for smart accounts. RSRegistry is a permissionless 

#### Modules

Modules are smart contracts that act as modular components that can be added to smart accounts.
The registry is agnostic towards smart account or module implementations.
Modules addresses and deployment metadata are [stored](./docs/ModuleRegistration.md) on the registry.

#### Authorities 
The RhinestoneRegistry allows Authorities to conduct comprehensive security assessments of third-party modules or other 
contracts before their integration. Authorities can check for potential vulnerabilities, adherence to best security practices, 
and code quality, ensuring that these modules don't introduce security risks to users or an integrated product (i.e. Smart Account).

#### Attestation Schemas
[Schemas](./docs/Schemas.md) are ABIs that define the data fields needed for attestations. 

#### Attestations
[Attestations](./docs/Attestation.md) are digital records of cryptographically signed artifacs that attest to security / safety of a module. 


#### Transparency and Trust
By openly verifying and validating third-party modules, Authorities build trust with the ecosystem and their user base. 
Users will have the confidence that each module integrated into their Smart Account has been thoroughly assessed for security, 
reducing their risk while improving the user experience of modular smart accounts.

#### Management of Updates
Modules evolve over time, with developers releasing new versions to add features or address security 
vulnerabilities. Authorities can ensure that only the latest and safest versions of these modules are active in your system, 
enhancing the overall security and functionality. Authorities may also chose to revoke attestations made in the past.

#### Cross-Chain Consistency
If your product operates [across multiple Ethereum](./docs/L2Propagation.md) chains, the RhinestoneRegistry can ensure the consistency of modules across these chains. 
This feature will prevent versioning issues, guaranteeing that users experience the same level of security and functionality, 
irrespective of the chain they're on.

## Architecture

The RhinestoneRegistry is designed as a permissionless hyperstructure. 
This architecture enables the registry to effectively manage and coordinate various types of smart contracts, 
spanning multiple developers and authorities. With this level of interconnectedness, smart contracts can freely interact with each other and with 
various authorities, opening up a world of possibilities for rich, complex interactions. It promotes a decentralized, collaborative environment, 
where entities can share, validate, and verify smart contracts across chains.


![Architecture](./public/docs/architecture.png)



### Limitations
- EAS does not support ERC1721, could make sense to fork EAS and add support. Added [PR](https://github.com/ethereum-attestation-service/eas-contracts/pull/65) to EAS
- who select bridged for propagation
    could let schema owner select bridges required


### Prerequisites
- Solidity version 0.8.19 or later
- External dependencies: Hashi's Yaho.sol and Hashi's Yaru.sol
- Interface: IRSAuthority.sol
- Library: RSRegistryLib.sol
- External contract: console2.sol

### Usage
1. Deploy the RSRegistry contract, passing instances of Yaho and Yaru contracts as well as the address of the L1 registry contract (if applicable).
1. Add authorities by calling the addAuthority function and providing a URL related to the verifier.
1. Deploy or register contracts by calling the deploy or register functions, respectively. These functions require the contract creation code, deployment parameters, and additional data.
1. Verify contracts by calling the verify function and providing the contract address,
risk level, confidence level, data, code hash, and attestation state.
1. Fetch attestation data from authorities by calling the fetchAttestation function.
This function retrieves attestation records for a given module from a list of authorities and requires a certain threshold of verifications to succeed.
1. Dispatch attestation messages to other chains by calling the dispatchAttestation function. 
This function encodes the attestation record into a data payload and sends it to the specified chain using Yaho contract.
1. Receive attestation messages from L1 by calling the receiveL1attestation function. 
This function should only be called by a valid caller (Yaru contract) and stores the received attestation record.
