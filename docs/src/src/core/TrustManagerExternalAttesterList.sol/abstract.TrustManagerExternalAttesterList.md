# TrustManagerExternalAttesterList
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/core/TrustManagerExternalAttesterList.sol)

**Inherits:**
[IRegistry](/src/IRegistry.sol/interface.IRegistry.md)

If smart accounts want to query the registry, and supply a list of trusted attesters in calldata, this component can be used

*This contract is abstract and provides utility functions to query attestations with a calldata provided list of attesters*


## Functions
### check


```solidity
function check(address module, address attester) external view returns (uint256 attestedAt);
```

### checkN


```solidity
function checkN(address module, address[] calldata attesters, uint256 threshold) external view returns (uint256[] memory attestedAtArray);
```

### _getAttestation


```solidity
function _getAttestation(address module, address attester) internal view virtual returns (AttestationRecord storage $attestation);
```

