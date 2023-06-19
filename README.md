<img align="right" width="150" height="150" top="100" src="./public/readme.jpg">

# Rhinestone Regsitry • [![tests](https://github.com/rhinestonewtf/registry/actions/workflows/ci.yml/badge.svg?label=tests)](https://github.com/rhinestonewtf/registry/actions/workflows/ci.yml) ![license](https://img.shields.io/github/license/rhinestonewtf/registry?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.17-lightgrey)

This Contract is in active development. Do not use this in Prod!


### Intro
- registry allows devs to register components/modules
- authorities can attest to security assumptions to modules
- registry supports multiple atteastation schemas


### Schemas
- ABI based schema specificationta
- Ethereum Attestation Service Style Schemas 
- Resolvers can implement arbitraty checks if authorities issue new attestations for a schema
- Each module can support one schema
- anyone can register new schemas


### Attestation
- reference one schema
- utilize ABI encoded data fields according to schema
- additionally, data fields like: time, expirationTime, revocationTime, refUID, recipient, attester can be saved
- Attestattions can reference other Attestations, which makes it possible to chain related attestations, and break the chain of attestations should one be revoked
- Attestations are save in the Regsitry contract
- Attestations can be propagated to L2s where contract bytecode is identical to source chain




### Attestation Monetization
- Monetization can happen within 


### Limitations
- EAS does not support ERC1721, could make sense to fork EAS and add support
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

### Events
- Deployment(address indexed implementation, bytes32 codeHash): Triggered when a contract is deployed.
- Registration(address indexed implementation, bytes32 codeHash): Triggered when a contract is registered.
- Attestation(address indexed implementation, address indexed authority, Attestation attestation): Triggered when a contract is attested.
- Propagation(address indexed implementation, address indexed authority): Triggered when a contract attestation is propagated.

### Errors

- InvalidChainId(): Emitted when the provided chain ID is invalid.
- InvalidBridgeTarget(): Emitted when the bridge target is invalid.
- InvalidSender(address moduleAddr, address sender): Emitted when the sender address is invalid.
- InvalidCaller(address moduleAddr, address yaruSender): Emitted when the caller is not the Yaru contract.
- InvalidAttestation(address moduleAddr, address authority): Emitted when the attestation is invalid.
- InvalidCodeHash(bytes32 expected, bytes32 actual): Emitted when the contract hash is invalid.
- RiskTooHigh(uint8 risk): Emitted when the risk level is too high.
- AlreadyRegistered(address moduleAddr): Emitted when the contract is already registered.
- SecurityAlert(address moduleAddr, address authority): Emitted when a security alert occurs.
- ThresholdNotReached(uint256 threshold, address moduleAddr): Emitted when the minimum threshold of verifications is not reached.
