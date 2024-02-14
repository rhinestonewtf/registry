// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {
    AttestationDataRef,
    AttestationRecord,
    AttestationRequest,
    ModuleType,
    ModuleRecord,
    ResolverUID,
    ResolverRecord,
    RevocationRequest,
    SchemaUID,
    SchemaRecord
} from "./DataTypes.sol";

import { IExternalSchemaValidator } from "./external/IExternalSchemaValidator.sol";
import { IExternalResolver } from "./external/IExternalResolver.sol";

interface IERC7484 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          Check with Registry internal attesters            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function check(address module) external view;

    function checkForAccount(address smartAccount, address module) external view;

    function check(address module, ModuleType moduleType) external view;

    function checkForAccount(address smartAccount, address module, ModuleType moduleType) external view;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              Check with external attester(s)               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function check(address module, address attester) external view returns (uint256 attestedAt);

    function checkN(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray);
}

interface IRegistry is IERC7484 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*             Smart Account - Trust Management               */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event NewTrustedAttesters();

    error InvalidResolver(IExternalResolver resolver);
    error InvalidResolverUID(ResolverUID uid);
    error InvalidTrustedAttesterInput();
    error NoTrustedAttestersFound();
    error RevokedAttestation(address attester);
    error InvalidModuleType();
    error AttestationNotFound();

    error InsufficientAttestations();

    /**
     * Allows smartaccounts - the end users of the registry - to appoint
     * one or many attesters as trusted.
     *
     * @param threshold The minimum number of attestations required for a module
     *                  to be considered secure.
     * @param attesters The addresses of the attesters to be trusted.
     */
    function trustAttesters(uint8 threshold, address[] calldata attesters) external;

    /**
     * Get trusted attester for a specific smartAccount
     * @param smartAccount The address of the smartAccount
     */
    function findTrustedAttesters(address smartAccount) external view returns (address[] memory attesters);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Attestations                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event Revoked(address indexed moduleAddr, address indexed revoker, SchemaUID schema);
    event Attested(address indexed moduleAddr, address indexed attester, SchemaUID schemaUID, AttestationDataRef indexed sstore2Pointer);

    error AlreadyRevoked();
    error ModuleNotFoundInRegistry(address module);
    error AccessDenied();
    error InvalidAttestation();
    error InvalidExpirationTime();
    error DifferentResolvers();
    error InvalidSignature();
    error InvalidModuleTypes();

    /**
     * Allows msg.sender to attest to multiple modules' security status.
     * The AttestationRequest.Data provided should match the attestation
     * schema defined by the Schema corresponding to the SchemaUID
     *
     * @dev This function will revert if the same module is attested twice by the same attester.
     *      If you want to re-attest, you have to revoke your attestation first, and then attest again.
     *
     * @param schemaUID The SchemaUID of the schema the attestation is based on.
     * @param request a single AttestationRequest
     */
    function attest(SchemaUID schemaUID, AttestationRequest calldata request) external;

    /**
     * Allows msg.sender to attest to multiple modules' security status.
     * The AttestationRequest.Data provided should match the attestation
     * schema defined by the Schema corresponding to the SchemaUID
     *
     * @dev This function will revert if the same module is attested twice by the same attester.
     *      If you want to re-attest, you have to revoke your attestation first, and then attest again.
     *
     * @param schemaUID The SchemaUID of the schema the attestation is based on.
     * @param requests An array of AttestationRequest
     */
    function attest(SchemaUID schemaUID, AttestationRequest[] calldata requests) external;

    /**
     * Allows attester to attest by signing an AttestationRequest (ECDSA or ERC1271)
     * The AttestationRequest.Data provided should match the attestation
     * schema defined by the Schema corresponding to the SchemaUID
     *
     * @dev This function will revert if the same module is attested twice by the same attester.
     *      If you want to re-attest, you have to revoke your attestation first, and then attest again.
     *
     * @param schemaUID The SchemaUID of the schema the attestation is based on.
     * @param attester The address of the attester
     * @param request An AttestationRequest
     * @param signature The signature of the attester. ECDSA or ERC1271
     */
    function attest(SchemaUID schemaUID, address attester, AttestationRequest calldata request, bytes calldata signature) external;

    /**
     * Allows attester to attest by signing an AttestationRequest (ECDSA or ERC1271)
     * The AttestationRequest.Data provided should match the attestation
     * schema defined by the Schema corresponding to the SchemaUID
     *
     * @dev This function will revert if the same module is attested twice by the same attester.
     *      If you want to re-attest, you have to revoke your attestation first, and then attest again.
     *
     * @param schemaUID The SchemaUID of the schema the attestation is based on.
     * @param attester The address of the attester
     * @param requests An array of AttestationRequest
     * @param signature The signature of the attester. ECDSA or ERC1271
     */
    function attest(SchemaUID schemaUID, address attester, AttestationRequest[] calldata requests, bytes calldata signature) external;

    /**
     * Getter function to get AttestationRequest made by one attester
     */
    function findAttestation(address module, address attester) external view returns (AttestationRecord memory attestation);

    /**
     * Getter function to get AttestationRequest made by multiple attesters
     */
    function findAttestations(
        address module,
        address[] calldata attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Revocations                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Allows msg.sender to revoke an attstation made by the same msg.sender
     *
     * @dev this function will revert if the attestation is not found
     * @dev this function will revert if the attestation is already revoked
     *
     * @param request  the RevocationRequest
     */
    function revoke(RevocationRequest calldata request) external;

    /**
     * Allows msg.sender to revoke multiple attstations made by the same msg.sender
     *
     * @dev this function will revert if the attestation is not found
     * @dev this function will revert if the attestation is already revoked
     *
     * @param requests the RevocationRequests
     */
    function revoke(RevocationRequest[] calldata requests) external;

    /**
     * Allows attester to revoke an attestation by signing an RevocationRequest (ECDSA or ERC1271)
     *
     * @param attester the signer / revoker
     * @param request the RevocationRequest
     * @param signature ECDSA or ERC1271 signature
     */
    function revoke(address attester, RevocationRequest calldata request, bytes calldata signature) external;

    /**
     * Allows attester to revoke an attestation by signing an RevocationRequest (ECDSA or ERC1271)
     * @dev if you want to revoke multiple attestations, but from different attesters, call this function multiple times
     *
     * @param attester the signer / revoker
     * @param requests array of RevocationRequests
     * @param signature ECDSA or ERC1271 signature
     */
    function revoke(address attester, RevocationRequest[] calldata requests, bytes calldata signature) external;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    Module Registration                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    // Event triggered when a module is deployed.
    event ModuleRegistration(address indexed implementation, ResolverUID resolverUID, bool deployedViaRegistry);

    error AlreadyRegistered(address module);
    error InvalidDeployment();
    error ModuleAddressIsNotContract(address moduleAddress);
    error FactoryCallFailed(address factory);

    /**
     * This registry implements a CREATE2 factory, that allows module developers to register and deploy module bytecode
     * @param salt The salt to be used in the CREATE2 factory. This adheres to Pr000xy/Create2Factory.sol salt formatting.
     *             The salt's first bytes20 should be the address of the sender
     *             or bytes20(0) to bypass the check (this will lose replay protection)
     * @param resolverUID The resolverUID to be used in the CREATE2 factory
     * @param initCode The initCode to be used in the CREATE2 factory
     * @param metadata The metadata to be stored on the registry.
     *            This field is optional, and might be used by the module developer to store additional
     *            information about the module or facilitate business logic with the Resolver stub
     */
    function deployModule(
        bytes32 salt,
        ResolverUID resolverUID,
        bytes calldata initCode,
        bytes calldata metadata
    )
        external
        payable
        returns (address moduleAddr);

    /**
     * Registry can use other factories to deploy the module
     * @notice This function is used to deploy and register a module using a factory contract.
     *           Since one of the parameters of this function is a unique resolverUID and any
     *           registered module address can only be registered once,
     *           using this function is of risk for a frontrun attack
     */
    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddress);

    /**
     * Already deployed module addresses can be registered on the registry
     * @notice This function is used to deploy and register an already deployed module.
     *           Since one of the parameters of this function is a unique resolverUID and any
     *           registered module address can only be registered once,
     *           using this function is of risk for a frontrun attack
     * @param resolverUID The resolverUID to be used for the module
     * @param moduleAddress The address of the module to be registered
     * @param metadata The metadata to be stored on the registry.
     *            This field is optional, and might be used by the module developer to store additional
     *            information about the module or facilitate business logic with the Resolver stub
     */
    function registerModule(ResolverUID resolverUID, address moduleAddress, bytes calldata metadata) external;

    /**
     * in conjunction with the deployModule() function, this function let's you
     * predict the address of a CREATE2 module deployment
     * @param salt CREATE2 salt
     * @param initCode module initcode
     * @return moduleAddress counterfactual address of the module deployment
     */
    function calcModuleAddress(bytes32 salt, bytes calldata initCode) external view returns (address);

    /**
     * Getter function to get the stored ModuleRecord for a specific module address.
     * @param moduleAddress The address of the module
     */
    function findModule(address moduleAddress) external view returns (ModuleRecord memory moduleRecord);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Manage Schemas                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event SchemaRegistered(SchemaUID indexed uid, address indexed registerer);

    error SchemaAlreadyExists(SchemaUID uid);

    error InvalidSchema();
    error InvalidSchemaValidator(IExternalSchemaValidator validator);

    /**
     * Register Schema and (optional) external IExternalSchemaValidator
     * Schemas describe the structure of the data of attestations
     * every attestation made on this registry, will reference a SchemaUID to
     *  make it possible to decode attestation data in human readable form
     * overrwriting a schema is not allowed, and will revert
     * @param schema ABI schema used to encode attestations that are made with this schema
     * @param validator (optional) external schema validator that will be used to validate attestations.
     *                  use address(0), if you dont need an external validator
     * @return uid SchemaUID of the registered schema
     */
    function registerSchema(
        string calldata schema,
        IExternalSchemaValidator validator // OPTIONAL
    )
        external
        returns (SchemaUID uid);

    /**
     * getter function to retrieve SchemaRecord
     */
    function findSchema(SchemaUID uid) external view returns (SchemaRecord memory record);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     Manage Resolvers                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event NewResolver(ResolverUID indexed uid, address indexed resolver);
    event NewResolverOwner(ResolverUID indexed uid, address newOwner);

    error ResolverAlreadyExists();

    /**
     * Allows Marketplace Agents to register external resolvers.
     * @param  resolver external resolver contract
     * @return uid ResolverUID of the registered resolver
     */
    function registerResolver(IExternalResolver resolver) external returns (ResolverUID uid);

    /**
     * Entities that previously regsitered an external resolver, may update the implementation address.
     * @param uid The UID of the resolver.
     * @param resolver The new resolver implementation address.
     */
    function setResolver(ResolverUID uid, IExternalResolver resolver) external;

    /**
     * Transfer ownership of resolverUID to a new address
     * @param uid The UID of the resolver to transfer ownership for
     * @param newOwner The address of the new owner
     */
    function transferResolverOwnership(ResolverUID uid, address newOwner) external;

    /**
     * Getter function to get the ResolverRecord of a registerd resolver
     * @param uid The UID of the resolver.
     */
    function findResolver(ResolverUID uid) external view returns (ResolverRecord memory record);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Stub Errors                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error ExternalError_SchemaValidation();
    error ExternalError_ResolveAtteststation();
    error ExternalError_ResolveRevocation();
    error ExternalError_ModuleRegistration();
}
