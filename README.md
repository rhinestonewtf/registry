<img align="right" width="150" height="150" top="100" src="./public/readme.jpg">

# Rhinestone Registry • RSRegistry ![license](https://img.shields.io/github/license/rhinestonewtf/registry?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.17-lightgrey)

This Contract is in active development. Do not use this in Prod!

## Intro

As the number of smart contracts grows, so too does the complexity of managing and 
verifying their legitimacy and security. In response to this, we introduce 
RhinestoneRegistry, a permissionless smart contract that serves as a registry for 
managing various types of records, including contract implementations. It also enables 
cross-chain verification of contracts, enhancing the security and interoperability of the Ethereum ecosystem.

RhinestoneRegistry is a smart contract designed to function as a decentralized registry 
and verification system for other smart contracts on the Ethereum platform. With an 
emphasis on contract security and transparency, it allows attesters to register, 
verify, and dispatch verification statuses across various Ethereum chains.


## Core Principles
### Attestations
[Attestations](./docs/Attestation.md) represent digitally documented assertions made by any entity 
about the security poture of account abstraction modules, 
serving as a seal of authenticity for the associated data. An entity known as an 
Attestor forms these records, authenticating them with their Ethereum wallet 
and then registering them on the Ethereum blockchain. The accessibility of 
these attestations for verification is universal, provided one has access 
to the Ethereum blockchain and the unique UID of the attestation.

An attestation consists of two primary elements: the schema and the 
attestation data. The schema acts as a standardized structure for 
creating and validating attestations, defining the data types, 
format, and composition. The Rhinestone Registry uses Solidity 
ABI types as acceptable fields in these schemas. The attestation 
data represents the actual information subject to attestation. 
To be classified as a valid attestation, it should adhere to the 
structure defined in the schema.

The significance of attestations lies in their ability to 
facilitate trust and credibility within the blockchain. In 
scenarios lacking physical interaction or presence, verifying 
the veracity or reliability of information can be demanding. 
Attestations address this challenge by providing third-party 
validation and a cryptographically signed confirmation of 
information authenticity, thus enhancing the information's 
trustworthiness for others.

### Schemas
[Schemas](./docs/Schema.md) represent predefined structures utilized for the formation and 
verification of attestations. They define the data types, format, and 
composition of an attestation. The Rhinestone Registry accepts Solidity 
ABI types as acceptable fields for schemas. Schemas play an essential 
role as they establish a shared format and structure for attestation 
data, enabling the creation and verification of various attestations 
in a trustless fashion. This functionality paves the way for 
interoperability and composability amongst different attestation protocols and solutions.

### Attestors
Attestors refer to individuals or organizations responsible for 
creating and signing attestations. They add the attestation to the 
Ethereum blockchain, making it available for verification. Any 
individual owning an Ethereum wallet can become an Attestor and 
can formulate attestations for a variety of purposes.

### Modules
Modules are smart contracts that act as modular components that can be added to smart accounts. 
The registry is agnostic towards smart account or module implementations. Modules addresses and 
deployment metadata are stored on the registry.

Modules are registered on the Rhinestone Registry by [deploying](./docs/ModulesRegistration.md) the Module Bytecode with `CREATE2`


### Cross-Chain Consistency
For account abstraction modules that can be used [across multiple Ethereum](./docs/L2Propagation.md) chains,
the Rhinestone Registry can ensure the consistency of modules across these chains. 
This feature will prevent versioning issues, guaranteeing that users experience the same level of security and functionality, 
irrespective of the chain they're on.

### Users
Users represent entities that depend on attestations to inform 
decisions or initiate actions. They utilize the information enclosed 
within the attestation to confirm its authenticity and integrity. The 
backing for these attestations often lies in the reputation and 
trustworthiness of the Attestor.

### Ethereum ABI Types
The Ethereum Application Binary Interface (ABI) stipulates the data 
types that can be incorporated in smart contracts and other Ethereum transactions. 
EAS accepts ABI types as valid fields for schemas.

## Architecture

The Rhinestone Registry is designed as a permissionless hyperstructure. 
This architecture enables the registry to effectively manage and coordinate various types of smart contracts, 
spanning multiple developers and authorities. With this level of interconnectedness, smart contracts can freely interact with each other and with 
various authorities, opening up a world of possibilities for rich, complex interactions. It promotes a decentralized, collaborative environment, 
where entities can share, validate, and verify smart contracts across chains.


![Architecture](./public/docs/architecture.png)


## Noteable Mentions
- Rhinestone Registry is leveraging an attestation logic inspired by EAS

### Prerequisites
- Solidity version 0.8.19 or later
- External dependencies: Hashi's Yaho.sol and Hashi's Yaru.sol

