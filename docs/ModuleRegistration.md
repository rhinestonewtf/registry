
# Module Registration
The Module Registration function is used to deploy new smart account modules onto the Ethereum network. The function uses the CREATE2 opcode, allowing the contract to determine the address where the smart account module will be deployed before the actual deployment transaction is sent. The registration process requires one schema ID to be associated with the new module.

To register modules on the registry, they have to be deployed via the registry and CREATE2. 
Every module is registered with a corsponding resolverUID.

## Support for 3rd party factories

In order to make the integration into existing business logics possible, 
the registry is able to utilize external factories that can be utilized to deploy the modules.


## Storage 


After deploying the module bytecode, the registry saves the deployment address as well as the chosen `resolverUID`, 
in addition to the following metadata.
```solidity

struct ModuleRecord {
    ResolverUID resolverUID; // The unique identifier of the Resolver
    address implementation; // The deployed contract address
    address sender; // The address of the sender who deployed the contract
    bytes data; // Additional data related to the contract deployment
}
```


