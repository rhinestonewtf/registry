## Intro

To register modules on the registry, they have to be deployed via the registry and CREATE2. 
After deploying the bytecode, the registry will save the extcodehash of the depoyed contract.
Every module is registered with a corsponding schemaUID.

![Registration](../public/docs/module-registration.png)

## Challenges
- Register already deployed contracts
