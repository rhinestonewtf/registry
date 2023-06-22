## Intro

to register modules on the registry, they have to be deployed via the registry and CREATE2. 
after deploying the bytecode, the registry will safe the extcodehash of the depoyed contract.
every module is registered with a corsponding schemaUID.

![Registration](../public/docs/module-registration.png)

## challenges
- register already deployed contracts
