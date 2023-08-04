# Integrations

We are providing simple abstract constracts that provides a standard set of functionalities to 
facilitate smooth interactions with the registry, while also offering the flexibility to be 
extended based on your unique requirements. Developers can build upon this abstract contract 
to interact with the registry and manage their plugins, validators, and recovery modules. 


## Installation


To install the registry to you foundry project, run:
```sh
forge install rhinestonewtf/registry
ls ./lib/registry/src/integrations/examples/
```


## Integrate into a smart account

Integration of the registry can be as simple as this:

```solidity
import {RegistryIntegration} from "registry/src/integrations/SimpleRegistryIntegration.sol";

contract SmartAccount is 
    RegistryIntegration, // <-- Inherit from RegistryIntegration
    IStandardExecutor {


    function execute(address target, uint256 value, bytes calldata data, FunctionReference validator)
    onlyWithRegistryCheck(target)// <-- performing check with REGISTRY INTEGRATION
    external
    payable {
    // ... logic
    }
}
```
