// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRegistry {
    function registerModule(bytes32 resolverUID, address moduleAddress, bytes calldata metadata, bytes calldata resolverContext) external;
}

interface IFactoryWithInit {
    event DeployedAndInitialized(address indexed addr, bytes32 indexed salt);

    error InvalidSalt();
    error InvalidAddress();
    error InitializationFailed();

    struct Deployment {
        bytes32 salt;
        bytes initCode;
        bytes initCall;
    }

    struct RegistryData {
        bytes32 resolverUID;
        bytes metadata;
        bytes resolverContext;
    }

    function deployInitRegister(
        Deployment calldata deployment,
        RegistryData calldata registryData
    )
        external
        payable
        returns (address deploymentAddress);
}

contract FactoryWithInit is IFactoryWithInit {
    IRegistry internal immutable REGISTRY;

    constructor(address registry) {
        REGISTRY = IRegistry(registry);
    }

    modifier containsCaller(bytes32 salt) {
        // prevent contract submissions from being stolen from tx.pool by requiring
        // that the first 20 bytes of the submitted salt match msg.sender.
        if ((address(bytes20(salt)) != msg.sender) && (bytes20(salt) != bytes20(0))) {
            revert InvalidSalt();
        }
        _;
    }

    function calcAddress(bytes memory initCode, bytes32 salt) public view returns (address targetDeploymentAddress) {
        targetDeploymentAddress = address(
            uint160( // downcast to match the address type.
                uint256( // convert to uint to truncate upper digits.
                    keccak256( // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked( // pack all inputs to the hash together.
                            hex"ff", // start with 0xff to distinguish from RLP.
                            address(this), // this contract will be the caller.
                            salt, // pass in the supplied salt value.
                            keccak256( // pass in the hash of initialization code.
                            abi.encodePacked(initCode))
                        )
                    )
                )
            )
        );
    }

    function deployInitRegister(
        Deployment calldata deployment,
        RegistryData calldata registryData
    )
        external
        payable
        containsCaller(deployment.salt)
        returns (address deploymentAddress)
    {
        // determine the target address for contract deployment.
        bytes memory initCode = deployment.initCode;
        bytes32 salt = deployment.salt;
        address targetDeploymentAddress = calcAddress(initCode, salt);

        // using inline assembly: load data and length of data, then call CREATE2.
        assembly {
            let encoded_data := add(0x20, initCode) // load initialization code.
            let encoded_size := mload(initCode) // load the init code's length.
            deploymentAddress :=
                create2( // call CREATE2 with 4 arguments.
                    callvalue(), // forward any attached value.
                    encoded_data, // pass in initialization code.
                    encoded_size, // pass in init code's length.
                    salt // pass in the salt value.
                )
        }

        // check address against target to ensure that deployment was successful.
        if (deploymentAddress != targetDeploymentAddress) revert InvalidAddress();

        (bool success,) = deploymentAddress.call(deployment.initCall);
        if (!success) {
            revert InitializationFailed();
        }

        REGISTRY.registerModule(registryData.resolverUID, deploymentAddress, registryData.metadata, registryData.resolverContext);
        emit DeployedAndInitialized(deploymentAddress, salt);
    }
}
