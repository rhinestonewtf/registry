# AttestationRecord
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/DataTypes.sol)


```solidity
struct AttestationRecord {
    uint48 time;
    uint48 expirationTime;
    uint48 revocationTime;
    PackedModuleTypes moduleTypes;
    address moduleAddr;
    address attester;
    AttestationDataRef dataPointer;
    SchemaUID schemaUID;
}
```

