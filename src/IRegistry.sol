// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    AttestationDataRef,
    AttestationRecord,
    AttestationRequest,
    ModuleType,
    ModuleRecord,
    ResolverUID,
    RevocationRequest,
    SchemaUID
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

    function checkForAccount(
        address smartAccount,
        address module,
        ModuleType moduleType
    )
        external
        view;

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
    function getTrustedAttesters(address smartAccount)
        external
        view
        returns (address[] memory attesters);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Attestations                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event Revoked(address indexed moduleAddr, address indexed revoker, SchemaUID schema);
    event Attested(
        address indexed moduleAddr,
        address indexed attester,
        SchemaUID schemaUID,
        AttestationDataRef sstore2Pointer
    );

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

    function attest(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest calldata request,
        bytes calldata signature
    )
        external;

    function attest(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest[] calldata requests,
        bytes calldata signature
    )
        external;

    function findAttestation(
        address module,
        address attester
    )
        external
        view
        returns (AttestationRecord memory attestation);

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

    function revoke(RevocationRequest calldata request) external;

    function revoke(RevocationRequest[] calldata requests) external;

    function revoke(
        address attester,
        RevocationRequest calldata request,
        bytes calldata signature
    )
        external;

    function revoke(
        address attester,
        RevocationRequest[] calldata requests,
        bytes calldata signature
    )
        external;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    Module Registration                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    // Event triggered when a module is deployed.
    event ModuleRegistration(
        address indexed implementation, address indexed sender, bytes32 resolver
    );
    event ModuleDeployed(address indexed implementation, bytes32 indexed salt, bytes32 resolver);
    event ModuleDeployedExternalFactory(
        address indexed implementation, address indexed factory, bytes32 resolver
    );

    error AlreadyRegistered(address module);
    error InvalidDeployment();

    function deployModule(
        bytes32 salt,
        ResolverUID resolverUID,
        bytes calldata code,
        bytes calldata deployParams,
        bytes calldata metadata
    )
        external
        payable
        returns (address moduleAddr);

    function registerModule(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata
    )
        external;

    function getRegisteredModules(address moduleAddress)
        external
        view
        returns (ModuleRecord memory moduleRecord);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Manage Schemas                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event SchemaRegistered(SchemaUID indexed uid, address registerer);

    error SchemaAlreadyExists(SchemaUID uid);

    error InvalidSchema();
    error InvalidSchemaValidator(IExternalSchemaValidator validator);

    function registerSchema(
        string calldata schema,
        IExternalSchemaValidator validator // OPTIONAL
    )
        external
        returns (SchemaUID uid);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     Manage Resolvers                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event NewResolver(ResolverUID indexed uid, address resolver);

    error ResolverAlreadyExists();

    function registerResolver(IExternalResolver _resolver) external returns (ResolverUID uid);

    function setResolver(ResolverUID uid, IExternalResolver resolver) external;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Stub Errors                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error ExternalError_SchemaValidation();
    error ExternalError_ResolveAtteststation();
    error ExternalError_ResolveRevocation();
    error ExternalError_ModuleRegistration();
}
