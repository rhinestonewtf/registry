// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
    SchemaUID,
    ResolverUID,
    AttestationRequest,
    AttestationRecord,
    AttestationDataRef,
    RevocationRequest,
    ModuleType
} from "./DataTypes.sol";

import { IExternalSchemaValidator } from "./external/IExternalSchemaValidator.sol";
import { IExternalResolver } from "./external/IExternalResolver.sol";

interface IRegistry {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Common Errors                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Query Registry                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function setAttester(uint8 threshold, address[] calldata attesters) external;

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
    /*                       Attestations                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function attest(SchemaUID schemaUID, AttestationRequest calldata request) external;

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

    function readAttestations(
        address module,
        address[] calldata attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations);

    function readAttestation(
        address module,
        address attester
    )
        external
        view
        returns (AttestationRecord memory attestation);

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

    function deploy(
        bytes32 salt,
        ResolverUID resolverUID,
        bytes calldata code,
        bytes calldata deployParams,
        bytes calldata metadata
    )
        external
        payable
        returns (address moduleAddr);

    function register(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata
    )
        external;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Manage Schemas                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/
    function registerSchema(
        string calldata schema,
        IExternalSchemaValidator validator // OPTIONAL
    )
        external
        returns (SchemaUID uid);

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     Manage Resolvers                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function registerResolver(IExternalResolver _resolver) external returns (ResolverUID uid);

    function setResolver(ResolverUID uid, IExternalResolver resolver) external;

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
    // EVENTS
    error AlreadyExists();
    error InvalidSignature();
    error InvalidResolver();
    error InvalidModuleType();
    /**
     * @dev Emitted when a new schema has been registered
     *
     * @param uid The schema UID.
     * @param registerer The address of the account used to register the schema.
     */

    event SchemaRegistered(SchemaUID indexed uid, address registerer);

    event SchemaResolverRegistered(ResolverUID indexed uid, address registerer);

    /**
     * @dev Emitted when a new schema resolver
     *
     * @param uid The schema UID.
     * @param resolver The address of the resolver.
     */
    event NewSchemaResolver(ResolverUID indexed uid, address resolver);

    error DifferentResolvers();
    error AlreadyRevoked();
    error AccessDenied();
    error NotFound();
    error InvalidAttestation();
    error InvalidExpirationTime();

    event Revoked(address moduleAddr, address revoker, SchemaUID schema);
    event Attested(
        address moduleAddr, address attester, SchemaUID schemaUID, AttestationDataRef sstore2Pointer
    );

    error RevokedAttestation(address attester);
    error AttestationNotFound();
    error NoAttestersFound();
}
