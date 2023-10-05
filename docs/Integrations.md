# Integrations

The Integrations are a set of simple abstract constracts that provides a standard set of functionalities to
facilitate smooth interactions with the registry, while also offering the flexibility to be
extended based on unique requirements. Developers can build upon the abstract contracts
to interact with the registry and manage their modules.

## Installation

To install the registry to your foundry project, run:

```sh
forge install rhinestonewtf/registry
ls ./lib/registry/src/integrations/examples/
```

## Integrate into a Smart Account

Integration of the registry can be as simple as this:

```solidity
import {RegistryIntegration} from "registry/src/integrations/SimpleRegistryIntegration.sol";

contract SmartAccount is
    RegistryIntegration, // <-- Inherit from RegistryIntegration
    IStandardExecutor {

        function execute(address target, uint256 value, bytes calldata data, FunctionReference validator)
        onlyWithRegistryCheck(target)// <-- performing check with REGISTRY INTEGRATION
        external
        payable
        {
        // ... logic
        }
    }
```
