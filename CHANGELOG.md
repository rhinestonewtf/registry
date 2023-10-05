# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[0.0.2]: https://github.com/rhinestonewtf/registry/releases/tag/v0.0.2
[0.0.1]: https://github.com/rhinestonewtf/registry/releases/tag/v0.0.1

## [0.0.2] - 05-10-2023

### Changed

- Removal of Cross-chain Propagation
- Splitting up Resolvers into Resolvers and SchemaValidators
- Restructured files for improved readability

### Added

- Non-delegated attestations can now be made without a signature
- Full ERC1271 support
- SSTORE2 to store attestation data

### Removed

- Attestation UIDs
