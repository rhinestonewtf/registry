# IExternalSchemaValidator
[Git Source](https://github.com/rhinestonewtf/registry/blob/350cdd9001705a91cd42a82c8ee3e0cd055714e5/src/external/IExternalSchemaValidator.sol)

**Inherits:**
IERC165


## Functions
### validateSchema

Validates an attestation request.


```solidity
function validateSchema(AttestationRecord calldata attestation) external returns (bool);
```

### validateSchema

Validates an array of attestation requests.


```solidity
function validateSchema(AttestationRecord[] calldata attestations) external returns (bool);
```

