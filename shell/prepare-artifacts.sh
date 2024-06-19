
#!/usr/bin/env bash

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail


# Delete the current artifacts
artifacts=./artifacts
rm -rf $artifacts

# Create the new artifacts directories
mkdir $artifacts \
  "$artifacts/interfaces" 

FOUNDRY_PROFILE=optimized forge build

cp out-optimized/Registry.sol/Registry.json $artifacts


interfaces=./artifacts/interfaces

cp out-optimized/IRegistry.sol/IERC7484.json $interfaces
cp out-optimized/IRegistry.sol/IRegistry.json $interfaces
cp out-optimized/IExternalResolver.sol/IExternalResolver.json $interfaces
cp out-optimized/IExternalSchemaValidator.sol/IExternalSchemaValidator.json $interfaces

pnpm prettier --write ./artifacts
