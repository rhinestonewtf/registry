# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[0.2.1]: https://github.com/rhinestonewtf/registry/releases/tag/v0.2.1
[0.2.0]: https://github.com/rhinestonewtf/registry/releases/tag/v0.2.0
[0.1.0]: https://github.com/rhinestonewtf/registry/releases/tag/v0.1.0

## [0.2.1] - 22-11-2023

### Changed

- Refactored multiAttest code
- Standardized naming
- Import remappings

### Added

- Gas optimizations of query functions
- Expanded test coverage

### Removed

- Unchecked increments in loops

## [0.2.0] - 25-10-2023

### Changed

- Splitting up Resolvers into Resolvers and SchemaValidators
- Restructured files for improved readability

### Added

- Non-signed attestations can now be made without a signature
- Full ERC1271 support
- SSTORE2 to store attestation data

### Removed

- Attestation UIDs
- Cross-chain Propagation
