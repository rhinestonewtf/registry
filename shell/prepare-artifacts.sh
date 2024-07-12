
#!/usr/bin/env bash

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail


# Delete the current artifacts
artifacts=./artifacts
rm -rf $artifacts

# Create the new artifacts directories
mkdir $artifacts \
  "$artifacts/interfaces" 

forge build

cp out/Registry.sol/Registry.json $artifacts
cp out/MockERC1271Attester.sol/MockERC1271Attester.json $artifacts
cp out/MockResolver.sol/MockResolver.json $artifacts
cp out/MockSchemaValidator.sol/MockSchemaValidator.json $artifacts



interfaces=./artifacts/interfaces

cp out/IERC7484.sol/IERC7484.json $interfaces
cp out/IRegistry.sol/IRegistry.json $interfaces
cp out/IExternalResolver.sol/IExternalResolver.json $interfaces
cp out/IExternalSchemaValidator.sol/IExternalSchemaValidator.json $interfaces

pnpm prettier --write ./artifacts
