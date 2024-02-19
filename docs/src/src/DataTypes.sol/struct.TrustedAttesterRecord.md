# TrustedAttesterRecord
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/DataTypes.sol)


```solidity
struct TrustedAttesterRecord {
    uint8 attesterCount;
    uint8 threshold;
    address attester;
    mapping(address attester => address linkedAttester) linkedAttesters;
}
```

