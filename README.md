<img align="right" width="150" height="150" top="100" src="./public/readme.jpg">

# Rhinestone Regsitry • [![tests](https://github.com/rhinestonewtf/registry/actions/workflows/ci.yml/badge.svg?label=tests)](https://github.com/rhinestonewtf/registry/actions/workflows/ci.yml) ![license](https://img.shields.io/github/license/rhinestonewtf/registry?label=license) ![solidity](https://img.shields.io/badge/solidity-^0.8.17-lightgrey)

This Contract is in active development. Do not use this in Prod!

### Introduction

RSGenericRegistry is a smart contract developed for the Ethereum platform, written in Solidity. It acts as a registry for managing various types of records, including contract implementations. The contract is designed with interoperability in mind and can dispatch and receive verification messages across different Ethereum chains.


### Features
1. Deployment and Registration of Contracts: The contract provides functionality for deploying and registering other smart contracts.

1. Verification of Contracts: This contract allows for verification of other contracts by designated authorities. The verification process includes checking the risk level associated with the contract, the confidence level in the verification, and ensuring the code hash of the contract is valid.

1. Cross-Chain Communication: The contract can dispatch verification messages to other chains and receive verification messages from Layer 1 (L1) Ethereum networks.

1. Authorities Management: The contract allows for the addition of authority for verification purposes. Each authority is associated with a signer's address and a URL.

1. Risk Assessment: The contract allows querying of a contract's verification status, including the risk level.

### External Dependencies
This contract makes use of the following external contracts:

1. Yaho.sol and Yaru.sol from Hashi

### Smart Contract Structure
The contract defines several important structs that help in managing data:

1. VerifierInfo - Holds information about the verifier.
1. VerificationRecord - Holds a record of a verification process.
1. ContractArtifact - Represents a contract artifact.
It also includes a library, RSGenericRegistryLib, that provides helper functions for contract operations such as getCodeHash and deploy.

### Events
The contract emits several events to aid in tracking the contract's activities. They are Deployment, Registration, Verification, and Propagation.

### Error Handling
The contract has defined several custom errors for better error handling like InvalidChainId, InvalidBridgeTarget, InvalidSender, InvalidCaller, InvalidVerification, InvalidCodeHash, and RiskTooHigh.

### Conclusion
This contract is a versatile registry and verification solution for smart contracts on the Ethereum platform. It emphasizes secure and validated contract interaction and promotes cross-chain communication.

Note: This contract should be used by developers who are familiar with Ethereum, Solidity, and smart contract development.

### Disclaimer
This contract has not been audited. Use at your own risk. The author is not responsible for any issues that may arise from its use. Always ensure you understand how the contract works before interacting with it.

