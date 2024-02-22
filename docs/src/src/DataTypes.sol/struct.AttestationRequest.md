# AttestationRequest
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/DataTypes.sol)

*A struct representing the arguments of the attestation request.*


```solidity
struct AttestationRequest {
    address moduleAddr;
    uint48 expirationTime;
    bytes data;
    ModuleType[] moduleTypes;
}
```

