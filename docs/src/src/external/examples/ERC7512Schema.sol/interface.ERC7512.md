# ERC7512
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/external/examples/ERC7512Schema.sol)


## Errors
### ERC7512_InvalidModuleAddr

```solidity
error ERC7512_InvalidModuleAddr();
```

## Structs
### Auditor

```solidity
struct Auditor {
    string name;
    string uri;
    string[] authors;
}
```

### Contract

```solidity
struct Contract {
    bytes32 chainId;
    address deployment;
}
```

### Signature

```solidity
struct Signature {
    SignatureType sigType;
    address signer;
    bytes data;
}
```

### AuditSummary

```solidity
struct AuditSummary {
    Auditor auditor;
    uint256 issuedAt;
    uint256[] ercs;
    Contract auditedContract;
    bytes32 auditHash;
    string auditUri;
    uint256 signedAt;
    Signature auditorSignature;
}
```

## Enums
### SignatureType

```solidity
enum SignatureType {
    SECP256K1,
    ERC1271
}
```

