// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

/**
 * @title The interface of an optional schema resolver.
 */
interface IExternalSchemaValidator is IERC165 {
    /**
     * @notice Validates an attestation request.
     */
    function validateSchema(AttestationRecord calldata attestation) external view returns (bool);

    /**
     * @notice Validates an array of attestation requests.
     */
    function validateSchema(AttestationRecord[] calldata attestations)
        external
        view
        returns (bool);
}

/**
 * @title The interface of an optional schema resolver.
 * @dev The resolver is responsible for validating the schema and attestation data.
 * @dev The resolver is also responsible for processing the attestation and revocation requests.
 *
 */
interface IExternalResolver is IERC165 {
    /**
     * @dev Processes an attestation and verifies whether it's valid.
     *
     * @param attestation The new attestation.
     *
     * @return Whether the attestation is valid.
     */
    function resolveAttestation(AttestationRecord calldata attestation)
        external
        payable
        returns (bool);

    function resolveAttestation(AttestationRecord[] calldata attestation)
        external
        payable
        returns (bool);

    /**
     * @dev Processes an attestation revocation and verifies if it can be revoked.
     *
     * @param attestation The existing attestation to be revoked.
     *
     * @return Whether the attestation can be revoked.
     */
    function resolveRevocation(AttestationRecord calldata attestation)
        external
        payable
        returns (bool);
    function resolveRevocation(AttestationRecord[] calldata attestation)
        external
        payable
        returns (bool);

    /**
     * @dev Processes a Module Registration
     *
     * @param module Module registration artefact
     *
     * @return Whether the registration is valid
     */
    function resolveModuleRegistration(ModuleRecord calldata module)
        external
        payable
        returns (bool);
}

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                     Storage Structs                        */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

// Struct that represents an attestation.
struct AttestationRecord {
    uint48 time; // The time when the attestation was created (Unix timestamp).
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    uint48 revocationTime; // The time when the attestation was revoked (Unix timestamp).
    PackedModuleTypes moduleTypes; // bit-wise encoded module types. See ModuleTypeLib
    SchemaUID schemaUID; // The unique identifier of the schema.
    address moduleAddr; // The implementation address of the module that is being attested.
    address attester; // The attesting account.
    AttestationDataRef dataPointer; // SSTORE2 pointer to the attestation data.
}

// Struct that represents Module artefact.
struct ModuleRecord {
    ResolverUID resolverUID; // The unique identifier of the resolver.
    address sender; // The address of the sender who deployed the contract
    bytes metadata; // Additional data related to the contract deployment
}

struct SchemaRecord {
    uint48 registeredAt; // The time when the schema was registered (Unix timestamp).
    IExternalSchemaValidator validator; // Optional external schema validator.
    string schema; // Custom specification of the schema (e.g., an ABI).
}

struct ResolverRecord {
    IExternalResolver resolver; // Optional resolver.
    address resolverOwner; // The address of the account used to register the resolver.
}

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*            Attestation / Revocation Requests               */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

/**
 * @dev A struct representing the arguments of the attestation request.
 */
struct AttestationRequest {
    address moduleAddr; // The moduleAddr of the attestation.
    uint48 expirationTime; // The time when the attestation expires (Unix timestamp).
    bytes data; // Custom attestation data.
    ModuleType[] moduleTypes; // optional: The type(s) of the module.
}
/**
 * @dev A struct representing the arguments of the revocation request.
 */

struct RevocationRequest {
    address moduleAddr; // The module address.
}

/*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
/*                       Custom Types                         */
/*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

//---------------------- SchemaUID ------------------------------|
type SchemaUID is bytes32;

using { schemaEq as == } for SchemaUID global;
using { schemaNotEq as != } for SchemaUID global;

function schemaEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) == SchemaUID.unwrap(uid);
}

function schemaNotEq(SchemaUID uid1, SchemaUID uid) pure returns (bool) {
    return SchemaUID.unwrap(uid1) != SchemaUID.unwrap(uid);
}

//--------------------- ResolverUID -----------------------------|
type ResolverUID is bytes32;

using { resolverEq as == } for ResolverUID global;
using { resolverNotEq as != } for ResolverUID global;

function resolverEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) == ResolverUID.unwrap(uid2);
}

function resolverNotEq(ResolverUID uid1, ResolverUID uid2) pure returns (bool) {
    return ResolverUID.unwrap(uid1) != ResolverUID.unwrap(uid2);
}

type AttestationDataRef is address;

using { attestationDataRefEq as == } for AttestationDataRef global;

function attestationDataRefEq(
    AttestationDataRef uid1,
    AttestationDataRef uid2
)
    pure
    returns (bool)
{
    return AttestationDataRef.unwrap(uid1) == AttestationDataRef.unwrap(uid2);
}

type PackedModuleTypes is uint32;

type ModuleType is uint32;

using { moduleTypeEq as == } for ModuleType global;
using { moduleTypeNeq as != } for ModuleType global;

function moduleTypeEq(ModuleType uid1, ModuleType uid2) pure returns (bool) {
    return ModuleType.unwrap(uid1) == ModuleType.unwrap(uid2);
}

function moduleTypeNeq(ModuleType uid1, ModuleType uid2) pure returns (bool) {
    return ModuleType.unwrap(uid1) != ModuleType.unwrap(uid2);
}

library UIDLib {
    /**
     * @dev Calculates a UID for a given schema.
     *
     * @param schemaRecord The input schema.
     *
     * @return schema UID.
     */
    function getUID(SchemaRecord memory schemaRecord) internal pure returns (SchemaUID) {
        // TODO: this is a frontrunning vuln
        return SchemaUID.wrap(
            keccak256(abi.encodePacked(schemaRecord.schema, address(schemaRecord.validator)))
        );
    }

    /**
     * @dev Calculates a UID for a given resolver.
     *
     * @param resolver The input schema.
     *
     * @return ResolverUID.
     */
    function getUID(ResolverRecord memory resolver) internal pure returns (ResolverUID) {
        // TODO: this is a frontrunning vuln
        return ResolverUID.wrap(keccak256(abi.encodePacked(resolver.resolver)));
    }
}

// A representation of an empty/uninitialized UID.
bytes32 constant EMPTY_UID = 0;
ResolverUID constant EMPTY_RESOLVER_UID = ResolverUID.wrap(EMPTY_UID);
SchemaUID constant EMPTY_SCHEMA_UID = SchemaUID.wrap(EMPTY_UID);

// A zero expiration represents an non-expiring attestation.
uint256 constant ZERO_TIMESTAMP = 0;

address constant ZERO_ADDRESS = address(0);
ModuleType constant ZERO_MODULE_TYPE = ModuleType.wrap(0);

AttestationDataRef constant EMPTY_ATTESTATION_REF = AttestationDataRef.wrap(address(0));

/**
 * @dev Returns the current's block timestamp. This method is overridden during tests and used to simulate the
 * current block time.
 */
function _time() view returns (uint48) {
    return uint48(block.timestamp);
}

/**
 * @dev Returns whether an address is a contract.
 * @param addr The address to check.
 *
 * @return true if `account` is a contract, false otherwise.
 */
function _isContract(address addr) view returns (bool) {
    return addr.code.length > 0;
}

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
    error ModuleAddressIsNotContract(address moduleAddress);
    error FactoryCallFailed(address factory);

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

abstract contract SchemaManager is IRegistry {
    using UIDLib for SchemaRecord;
    // The global mapping between schema records and their IDs.

    mapping(SchemaUID uid => SchemaRecord schemaRecord) internal schemas;

    function registerSchema(
        string calldata schema,
        IExternalSchemaValidator validator // OPTIONAL
    )
        external
        onlySchemaValidator(validator)
        returns (SchemaUID uid)
    {
        SchemaRecord memory schemaRecord =
            SchemaRecord({ validator: validator, registeredAt: _time(), schema: schema });

        // Computing a unique ID for the schema using its properties
        uid = schemaRecord.getUID();

        if (schemas[uid].registeredAt != ZERO_TIMESTAMP) revert SchemaAlreadyExists(uid);

        // Storing schema in the _schemas mapping
        schemas[uid] = schemaRecord;

        emit SchemaRegistered(uid, msg.sender);
    }

    /**
     * If a validator is not address(0), we check if it supports the IExternalSchemaValidator interface
     */
    modifier onlySchemaValidator(IExternalSchemaValidator validator) {
        if (
            address(validator) != address(0)
                && !validator.supportsInterface(type(IExternalSchemaValidator).interfaceId)
        ) {
            revert InvalidSchemaValidator(validator);
        }
        _;
    }
}

/**
 * @title ModuleDeploymentLib
 * @dev A library that can be used to deploy the Registry
 * @author zeroknots
 */
library ModuleDeploymentLib {
    /**
     * @dev Gets the code hash of a contract at a given address.
     *
     * @param contractAddr The address of the contract.
     *
     * @return hash The hash of the contract code.
     */
    function codeHash(address contractAddr) internal view returns (bytes32 hash) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            if iszero(extcodesize(contractAddr)) { revert(0, 0) }
            hash := extcodehash(contractAddr)
        }
    }

    /**
     * @notice Creates a new contract using CREATE2 opcode.
     * @dev This method uses the CREATE2 opcode to deploy a new contract with a deterministic address.
     *
     * @param createCode The creationCode for the contract.
     * @param params The parameters for creating the contract. If the contract has a constructor,
     *               this MUST be provided. Function will fail if params are abi.encodePacked in createCode.
     * @param salt The salt for creating the contract.
     *
     * @return moduleAddress The address of the deployed contract.
     * @return initCodeHash packed (creationCode, constructor params)
     * @return contractCodeHash hash of deployed bytecode
     */
    function deploy(
        bytes memory createCode,
        bytes memory params,
        bytes32 salt,
        uint256 value
    )
        internal
        returns (address moduleAddress, bytes32 initCodeHash, bytes32 contractCodeHash)
    {
        bytes memory initCode = abi.encodePacked(createCode, params);
        // this enforces, that constructor params were supplied via params argument
        // if params were abi.encodePacked in createCode, this will revert
        initCodeHash = keccak256(initCode);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            moduleAddress := create2(value, add(initCode, 0x20), mload(initCode), salt)
            // If the contract was not created successfully, the transaction is reverted.
            if iszero(extcodesize(moduleAddress)) { revert(0, 0) }
            contractCodeHash := extcodehash(moduleAddress)
        }
    }

    /**
     * @notice Calculates the deterministic address of a contract that would be deployed using the CREATE2 opcode.
     * @dev The calculated address is based on the contract's code, a salt, and the address of the current contract.
     * @dev This function uses the formula specified in EIP-1014 (https://eips.ethereum.org/EIPS/eip-1014).
     *
     * @param _code The contract code that would be deployed.
     * @param _salt A salt used for the address calculation.
     *                 This must be the same salt that would be passed to the CREATE2 opcode.
     *
     * @return The address that the contract would be deployed
     *            at if the CREATE2 opcode was called with the specified _code and _salt.
     */
    function calcAddress(bytes memory _code, bytes32 _salt) internal view returns (address) {
        bytes32 hash =
            keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_code)));
        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint256(hash)));
    }

    error InvalidDeployment();
}

library StubLib {
    function requireExternalSchemaValidation(
        AttestationRecord memory attestationRecord,
        SchemaRecord storage schema
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        if (schema.registeredAt == ZERO_TIMESTAMP) revert IRegistry.InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (
            address(validator) != ZERO_ADDRESS
                && validator.validateSchema(attestationRecord) == false
        ) {
            revert IRegistry.ExternalError_SchemaValidation();
        }
    }

    function requireExternalSchemaValidation(
        AttestationRecord[] memory attestationRecords,
        SchemaRecord storage schema
    )
        internal
        view
    {
        // only run this function if the selected schemaUID exists
        if (schema.registeredAt == ZERO_TIMESTAMP) revert IRegistry.InvalidSchema();
        // validate Schema
        IExternalSchemaValidator validator = schema.validator;
        // if validator is set, call the validator
        if (
            address(validator) != ZERO_ADDRESS
                && validator.validateSchema(attestationRecords) == false
        ) {
            revert IRegistry.ExternalError_SchemaValidation();
        }
    }

    function requireExternalResolverOnAttestation(
        AttestationRecord memory attestationRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;
        if (resolverContract.resolveAttestation(attestationRecord) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnAttestation(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnRevocation(
        AttestationRecord memory attestationRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;
        if (resolverContract.resolveRevocation(attestationRecord) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnRevocation(
        AttestationRecord[] memory attestationRecords,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) == ZERO_ADDRESS) return;

        if (resolverContract.resolveAttestation(attestationRecords) == false) {
            revert IRegistry.ExternalError_ResolveAtteststation();
        }
    }

    function requireExternalResolverOnModuleRegistration(
        ModuleRecord memory moduleRecord,
        ResolverRecord storage resolver
    )
        internal
    {
        IExternalResolver resolverContract = resolver.resolver;

        if (address(resolverContract) != ZERO_ADDRESS) return;

        if (resolverContract.resolveModuleRegistration(moduleRecord) == false) {
            revert IRegistry.ExternalError_ModuleRegistration();
        }
    }
}

abstract contract ResolverManager is IRegistry {
    using UIDLib for ResolverRecord;

    mapping(ResolverUID uid => ResolverRecord resolver) public resolvers;

    /**
     * @dev Modifier to require that the caller is the owner of a resolver
     *
     * @param uid The UID of the resolver.
     */
    modifier onlyResolverOwner(ResolverUID uid) {
        if (resolvers[uid].resolverOwner != msg.sender) {
            revert AccessDenied();
        }
        _;
    }

    modifier notZero(ResolverUID uid) {
        if (uid == EMPTY_RESOLVER_UID) {
            revert InvalidResolverUID(uid);
        }
        _;
    }

    /**
     * If a resolver is not address(0), we check if it supports the IExternalResolver interface
     */
    modifier onlyResolver(IExternalResolver resolver) {
        if (
            address(resolver) == address(0)
                || !resolver.supportsInterface(type(IExternalResolver).interfaceId)
        ) {
            revert InvalidResolver(resolver);
        }
        _;
    }

    function registerResolver(IExternalResolver resolver)
        external
        onlyResolver(resolver)
        returns (ResolverUID uid)
    {
        // build a ResolverRecord from the input
        ResolverRecord memory resolverRecord =
            ResolverRecord({ resolver: resolver, resolverOwner: msg.sender });

        // Computing a unique ID for the schema using its properties
        uid = resolverRecord.getUID();

        // Checking if a schema with this UID already exists -> resolver can never be ZERO_ADDRESS
        if (address(resolvers[uid].resolver) != ZERO_ADDRESS) {
            revert ResolverAlreadyExists();
        }

        // SSTORE schema in the resolvers mapping
        resolvers[uid] = resolverRecord;

        emit NewResolver(uid, address(resolver));
    }

    // TODO: VULN:
    // Attacker could register the same resolver, thus be the owner of the resolverUID,
    // then set the resolver to a malicious contract
    function setResolver(
        ResolverUID uid,
        IExternalResolver resolver
    )
        external
        onlyResolver(resolver)
        onlyResolverOwner(uid) // authorization control
    {
        ResolverRecord storage referrer = resolvers[uid];
        referrer.resolver = resolver;
        emit NewResolver(uid, address(resolver));
    }
}

/**
 * @title Module
 *
 * @dev The Module contract serves as a component in a larger system for handling smart contracts or "modules"
 * within a blockchain ecosystem. This contract inherits from the IModule interface
 *
 * @dev The primary responsibility of the Module is to deploy and manage modules. A module is a smart contract
 * that has been deployed through the Module. The details of each module, such as its address, code hash, schema ID,
 * sender address, deploy parameters hash, and additional metadata are stored in
 *        a struct and mapped to the module's address in
 * the `_modules` mapping for easy access and management.
 *
 * @dev In conclusion, the Module is a central part of a system to manage,
 *    deploy, and interact with a set of smart contracts
 * in a structured and controlled manner.
 *
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 */
abstract contract ModuleManager is IRegistry, ResolverManager {
    using ModuleDeploymentLib for bytes;
    using ModuleDeploymentLib for address;
    using StubLib for *;

    mapping(address moduleAddress => ModuleRecord moduleRecord) internal _moduleAddrToRecords;

    function deployModule(
        bytes32 salt,
        ResolverUID resolverUID,
        bytes calldata code,
        bytes calldata deployParams,
        bytes calldata metadata
    )
        external
        payable
        returns (address moduleAddr)
    {
        ResolverRecord storage resolver = resolvers[resolverUID];
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver(resolver.resolver);

        // address predictedModuleAddress = code.calculateAddress(deployParams, salt);

        // TODO: should we use the initCode hash return value?
        (moduleAddr,,) = code.deploy(deployParams, salt, msg.value);
        // _storeModuleRecord() will check if module is already registered,
        // which should prevent reentry to any deploy function
        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddr, // TODO: is this reentrancy?
            sender: msg.sender,
            resolverUID: resolverUID,
            metadata: metadata
        });
        record.requireExternalResolverOnModuleRegistration(resolver);
    }

    function registerModule(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata
    )
        external
    {
        ResolverRecord storage resolver = resolvers[resolverUID];

        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolver(resolver.resolver);

        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddress,
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolverUID: resolverUID,
            metadata: metadata
        });
        // TODO: in case of registerModule() the resolver doesnt know the msg.sender since record.sender == address(0)s
        // is this a problemt?
        record.requireExternalResolverOnModuleRegistration(resolver);
    }

    function deployViaFactory(
        address factory,
        bytes calldata callOnFactory,
        bytes calldata metadata,
        ResolverUID resolverUID
    )
        external
        payable
        returns (address moduleAddress)
    {
        ResolverRecord storage resolver = resolvers[resolverUID];
        if (resolver.resolverOwner == ZERO_ADDRESS) revert InvalidResolverUID(resolverUID);
        // prevent someone from calling a registry function pretending its a factory
        if (factory == address(this)) revert FactoryCallFailed(factory);
        // call external factory to deploy module
        (bool ok, bytes memory returnData) = factory.call{ value: msg.value }(callOnFactory);
        if (!ok) revert FactoryCallFailed(factory);

        moduleAddress = abi.decode(returnData, (address));
        if (moduleAddress == ZERO_ADDRESS) revert InvalidDeployment();
        if (_isContract(moduleAddress) == false) revert ModuleAddressIsNotContract(moduleAddress);

        ModuleRecord memory record = _storeModuleRecord({
            moduleAddress: moduleAddress,
            // TODO: should we use msg.sender or the factory address?
            sender: ZERO_ADDRESS, // setting sender to address(0) since anyone can invoke this function
            resolverUID: resolverUID,
            metadata: metadata
        });
        // TODO: in case of registerModule() the resolver doesnt know the msg.sender since record.sender == address(0)s
        // is this a problemt?
        record.requireExternalResolverOnModuleRegistration(resolver);
    }

    function _storeModuleRecord(
        address moduleAddress,
        address sender,
        ResolverUID resolverUID,
        bytes calldata metadata
    )
        internal
        returns (ModuleRecord memory moduleRegistration)
    {
        // ensure that non-zero resolverUID was provided
        if (resolverUID == EMPTY_RESOLVER_UID) revert InvalidDeployment();
        // ensure moduleAddress is not already registered
        if (_moduleAddrToRecords[moduleAddress].resolverUID != EMPTY_RESOLVER_UID) {
            revert AlreadyRegistered(moduleAddress);
        }
        // revert if moduleAddress is NOT a contract
        // this should catch address(0)
        if (!_isContract(moduleAddress)) revert InvalidDeployment();

        // Store module metadata in _modules mapping
        moduleRegistration =
            ModuleRecord({ resolverUID: resolverUID, sender: sender, metadata: metadata });

        // Store module record in _modules mapping
        _moduleAddrToRecords[moduleAddress] = moduleRegistration;

        // Emit ModuleRegistration event
        emit ModuleRegistration(moduleAddress, sender, ResolverUID.unwrap(resolverUID));
    }

    function getRegisteredModules(address moduleAddress)
        external
        view
        returns (ModuleRecord memory moduleRecord)
    {
        return _moduleAddrToRecords[moduleAddress];
    }
}

abstract contract TrustManagerExternalAttesterList is IRegistry {
    function check(address module, address attester) external view returns (uint256 attestedAt) {
        AttestationRecord storage attestation = _getAttestation(module, attester);

        // attestedAt = attestation.time;
        uint256 expirationTime; // = attestation.expirationTime;
        uint256 revocationTime; // = attestation.revocationTime;

        // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
        // @dev the solidity version of the assembly code is above
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let mask := 0xffffffffffff
            let times := sload(attestation.slot)
            attestedAt := and(mask, times)
            times := shr(48, times)
            expirationTime := and(mask, times)
            times := shr(48, times)
            revocationTime := and(mask, times)
        }

        if (attestedAt == ZERO_TIMESTAMP) {
            revert AttestationNotFound();
        }

        if (expirationTime != ZERO_TIMESTAMP) {
            if (block.timestamp > expirationTime) {
                revert AttestationNotFound();
            }
        }

        if (revocationTime != ZERO_TIMESTAMP) {
            revert RevokedAttestation(attestation.attester);
        }
    }

    function checkN(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;
        attestedAtArray = new uint256[](attestersLength);

        for (uint256 i; i < attestersLength; ++i) {
            AttestationRecord storage attestation = _getAttestation(module, attesters[i]);

            uint256 attestationTime; // = attestation.time;
            uint256 expirationTime; // = attestation.expirationTime;
            uint256 revocationTime; // = attestation.revocationTime;

            // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
            // @dev the solidity version of the assembly code is above
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let mask := 0xffffffffffff
                let times := sload(attestation.slot)
                attestationTime := and(mask, times)
                times := shr(48, times)
                expirationTime := and(mask, times)
                times := shr(48, times)
                revocationTime := and(mask, times)
            }

            if (revocationTime != ZERO_TIMESTAMP) {
                revert RevokedAttestation(attestation.attester);
            }

            if (expirationTime != ZERO_TIMESTAMP) {
                if (timeNow > expirationTime) {
                    revert AttestationNotFound();
                }
            }

            attestedAtArray[i] = attestationTime;

            if (attestationTime == ZERO_TIMESTAMP) continue;
            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return attestedAtArray;
        revert InsufficientAttestations();
    }

    function checkNUnsafe(
        address module,
        address[] calldata attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray)
    {
        uint256 attestersLength = attesters.length;
        if (attestersLength < threshold || threshold == 0) {
            threshold = attestersLength;
        }

        uint256 timeNow = block.timestamp;
        attestedAtArray = new uint256[](attestersLength);

        for (uint256 i; i < attestersLength; ++i) {
            AttestationRecord storage attestation = _getAttestation(module, attesters[i]);

            uint256 attestationTime; // = attestation.time;
            uint256 expirationTime; // = attestation.expirationTime;
            uint256 revocationTime; // = attestation.revocationTime;

            // @dev this loads the three time values from storage, bit shifts them and assigns them to the variables
            // @dev the solidity version of the assembly code is above
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let mask := 0xffffffffffff
                let times := sload(attestation.slot)
                attestationTime := and(mask, times)
                times := shr(48, times)
                expirationTime := and(mask, times)
                times := shr(48, times)
                revocationTime := and(mask, times)
            }

            if (revocationTime != ZERO_TIMESTAMP) {
                attestedAtArray[i] = 0;
                continue;
            }

            attestedAtArray[i] = attestationTime;

            if (expirationTime != ZERO_TIMESTAMP) {
                if (timeNow > expirationTime) {
                    attestedAtArray[i] = 0;
                    continue;
                }
            }

            if (attestationTime == ZERO_TIMESTAMP) continue;
            if (threshold != 0) --threshold;
        }
        if (threshold == 0) return attestedAtArray;
        revert InsufficientAttestations();
    }

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        returns (AttestationRecord storage attestation);
}

library ModuleTypeLib {
    function isType(PackedModuleTypes self, ModuleType moduleType) internal pure returns (bool) {
        return (PackedModuleTypes.unwrap(self) & 2 ** ModuleType.unwrap(moduleType)) != 0;
    }

    function pack(ModuleType[] memory moduleTypes) internal pure returns (PackedModuleTypes) {
        uint32 result;
        uint256 length = moduleTypes.length;
        for (uint256 i; i < length; i++) {
            result = result + uint32(2 ** ModuleType.unwrap(moduleTypes[i]));
        }
        return PackedModuleTypes.wrap(result);
    }

    function packCalldata(ModuleType[] calldata moduleTypes)
        internal
        pure
        returns (PackedModuleTypes)
    {
        uint32 result;
        for (uint256 i; i < moduleTypes.length; i++) {
            uint32 _type = ModuleType.unwrap(moduleTypes[i]);
            if (_type > 31) revert IRegistry.InvalidModuleType();
            result = result + uint32(2 ** _type);
        }
        return PackedModuleTypes.wrap(result);
    }
}

/// @notice Optimized sorts and operations for sorted arrays.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Sort.sol)
library LibSort {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INSERTION SORT                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on small arrays (32 or lesser elements).
    // - Faster on almost sorted arrays.
    // - Smaller bytecode.
    // - May be suitable for view functions intended for off-chain querying.

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.
            let h := add(a, shl(5, n)) // High slot.
            let s := 0x20
            let w := not(0x1f)
            for { let i := add(a, s) } 1 {} {
                i := add(i, s)
                if gt(i, h) { break }
                let k := mload(i) // Key.
                let j := add(i, w) // The slot before the current slot.
                let v := mload(j) // The value of `j`.
                if iszero(gt(v, k)) { continue }
                for {} 1 {} {
                    mstore(add(j, s), v)
                    j := add(j, w) // `sub(j, 0x20)`.
                    v := mload(j)
                    if iszero(gt(v, k)) { break }
                }
                mstore(add(j, s), k)
            }
            mstore(a, n) // Restore the length of `a`.
        }
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(int256[] memory a) internal pure {
        _flipSign(a);
        insertionSort(_toUints(a));
        _flipSign(a);
    }

    /// @dev Sorts the array in-place with insertion sort.
    function insertionSort(address[] memory a) internal pure {
        insertionSort(_toUints(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      INTRO-QUICKSORT                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // - Faster on larger arrays (more than 32 elements).
    // - Robust performance.
    // - Larger bytecode.

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0x1f)
            let s := 0x20
            let n := mload(a) // Length of `a`.
            mstore(a, 0) // For insertion sort's inner loop to terminate.

            // Let the stack be the start of the free memory.
            let stack := mload(0x40)

            for {} iszero(lt(n, 2)) {} {
                // Push `l` and `h` to the stack.
                // The `shl` by 5 is equivalent to multiplying by `0x20`.
                let l := add(a, s)
                let h := add(a, shl(5, n))

                let j := l
                // forgefmt: disable-next-item
                for {} iszero(or(eq(j, h), gt(mload(j), mload(add(j, s))))) {} {
                    j := add(j, s)
                }
                // If the array is already sorted.
                if eq(j, h) { break }

                j := h
                // forgefmt: disable-next-item
                for {} iszero(gt(mload(j), mload(add(j, w)))) {} {
                    j := add(j, w) // `sub(j, 0x20)`.
                }
                // If the array is reversed sorted.
                if eq(j, l) {
                    for {} 1 {} {
                        let t := mload(l)
                        mstore(l, mload(h))
                        mstore(h, t)
                        h := add(h, w) // `sub(h, 0x20)`.
                        l := add(l, s)
                        if iszero(lt(l, h)) { break }
                    }
                    break
                }

                // Push `l` and `h` onto the stack.
                mstore(stack, l)
                mstore(add(stack, s), h)
                stack := add(stack, 0x40)
                break
            }

            for { let stackBottom := mload(0x40) } iszero(eq(stack, stackBottom)) {} {
                // Pop `l` and `h` from the stack.
                stack := sub(stack, 0x40)
                let l := mload(stack)
                let h := mload(add(stack, s))

                // Do insertion sort if `h - l <= 0x20 * 12`.
                // Threshold is fine-tuned via trial and error.
                if iszero(gt(sub(h, l), 0x180)) {
                    // Hardcode sort the first 2 elements.
                    let i := add(l, s)
                    if iszero(lt(mload(l), mload(i))) {
                        let t := mload(i)
                        mstore(i, mload(l))
                        mstore(l, t)
                    }
                    for {} 1 {} {
                        i := add(i, s)
                        if gt(i, h) { break }
                        let k := mload(i) // Key.
                        let j := add(i, w) // The slot before the current slot.
                        let v := mload(j) // The value of `j`.
                        if iszero(gt(v, k)) { continue }
                        for {} 1 {} {
                            mstore(add(j, s), v)
                            j := add(j, w)
                            v := mload(j)
                            if iszero(gt(v, k)) { break }
                        }
                        mstore(add(j, s), k)
                    }
                    continue
                }
                // Pivot slot is the average of `l` and `h`.
                let p := add(shl(5, shr(6, add(l, h))), and(31, l))
                // Median of 3 with sorting.
                {
                    function swap(a_, b_) -> _b, _a {
                        _b := a_
                        _a := b_
                    }
                    let e0 := mload(l)
                    let e1 := mload(h)
                    if iszero(lt(e0, e1)) { e1, e0 := swap(e0, e1) }
                    let e2 := mload(p)
                    if iszero(lt(e2, e1)) { e2, e1 := swap(e1, e2) }
                    if iszero(lt(e0, e2)) { e2, e0 := swap(e0, e2) }
                    mstore(p, e2)
                    mstore(h, e1)
                    mstore(l, e0)
                }
                // Hoare's partition.
                {
                    // The value of the pivot slot.
                    let x := mload(p)
                    p := h
                    for { let i := l } 1 {} {
                        for {} 1 {} {
                            i := add(i, s)
                            if iszero(gt(x, mload(i))) { break }
                        }
                        let j := p
                        for {} 1 {} {
                            j := add(j, w)
                            if iszero(lt(x, mload(j))) { break }
                        }
                        p := j
                        if iszero(lt(i, p)) { break }
                        // Swap slots `i` and `p`.
                        let t := mload(i)
                        mstore(i, mload(p))
                        mstore(p, t)
                    }
                }
                // If slice on right of pivot is non-empty, push onto stack.
                {
                    mstore(stack, add(p, s))
                    // Skip `mstore(add(stack, 0x20), h)`, as it is already on the stack.
                    stack := add(stack, shl(6, lt(add(p, s), h)))
                }
                // If slice on left of pivot is non-empty, push onto stack.
                {
                    mstore(stack, l)
                    mstore(add(stack, s), p)
                    stack := add(stack, shl(6, gt(p, l)))
                }
            }
            mstore(a, n) // Restore the length of `a`.
        }
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(int256[] memory a) internal pure {
        _flipSign(a);
        sort(_toUints(a));
        _flipSign(a);
    }

    /// @dev Sorts the array in-place with intro-quicksort.
    function sort(address[] memory a) internal pure {
        sort(_toUints(a));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  OTHER USEFUL OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // For performance, the `uniquifySorted` methods will not revert if the
    // array is not sorted -- it will simply remove consecutive duplicate elements.

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // If the length of `a` is greater than 1.
            if iszero(lt(mload(a), 2)) {
                let x := add(a, 0x20)
                let y := add(a, 0x40)
                let end := add(a, shl(5, add(mload(a), 1)))
                for {} 1 {} {
                    if iszero(eq(mload(x), mload(y))) {
                        x := add(x, 0x20)
                        mstore(x, mload(y))
                    }
                    y := add(y, 0x20)
                    if eq(y, end) { break }
                }
                mstore(a, shr(5, sub(x, a)))
            }
        }
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(int256[] memory a) internal pure {
        uniquifySorted(_toUints(a));
    }

    /// @dev Removes duplicate elements from a ascendingly sorted memory array.
    function uniquifySorted(address[] memory a) internal pure {
        uniquifySorted(_toUints(a));
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function searchSorted(uint256[] memory a, uint256 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(a, needle, 0);
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function searchSorted(int256[] memory a, int256 needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(_toUints(a), uint256(needle), 1 << 255);
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function searchSorted(address[] memory a, address needle)
        internal
        pure
        returns (bool found, uint256 index)
    {
        (found, index) = _searchSorted(_toUints(a), uint256(uint160(needle)), 0);
    }

    /// @dev Reverses the array in-place.
    function reverse(uint256[] memory a) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(mload(a), 2)) {
                let s := 0x20
                let w := not(0x1f)
                let h := add(a, shl(5, mload(a)))
                for { a := add(a, s) } 1 {} {
                    let t := mload(a)
                    mstore(a, mload(h))
                    mstore(h, t)
                    h := add(h, w)
                    a := add(a, s)
                    if iszero(lt(a, h)) { break }
                }
            }
        }
    }

    /// @dev Reverses the array in-place.
    function reverse(int256[] memory a) internal pure {
        reverse(_toUints(a));
    }

    /// @dev Reverses the array in-place.
    function reverse(address[] memory a) internal pure {
        reverse(_toUints(a));
    }

    /// @dev Returns a copy of the array.
    function copy(uint256[] memory a) internal pure returns (uint256[] memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let end := add(add(result, 0x20), shl(5, mload(a)))
            let o := result
            for { let d := sub(a, result) } 1 {} {
                mstore(o, mload(add(o, d)))
                o := add(0x20, o)
                if eq(o, end) { break }
            }
            mstore(0x40, o)
        }
    }

    /// @dev Returns a copy of the array.
    function copy(int256[] memory a) internal pure returns (int256[] memory result) {
        result = _toInts(copy(_toUints(a)));
    }

    /// @dev Returns a copy of the array.
    function copy(address[] memory a) internal pure returns (address[] memory result) {
        result = _toAddresses(copy(_toUints(a)));
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(uint256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := iszero(gt(p, mload(a)))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(int256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := iszero(sgt(p, mload(a)))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is sorted in ascending order.
    function isSorted(address[] memory a) internal pure returns (bool result) {
        result = isSorted(_toUints(a));
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(uint256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := lt(p, mload(a))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(int256[] memory a) internal pure returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := 1
            if iszero(lt(mload(a), 2)) {
                let end := add(a, shl(5, mload(a)))
                for { a := add(a, 0x20) } 1 {} {
                    let p := mload(a)
                    a := add(a, 0x20)
                    result := slt(p, mload(a))
                    if iszero(mul(result, xor(a, end))) { break }
                }
            }
        }
    }

    /// @dev Returns whether the array is strictly ascending (sorted and uniquified).
    function isSortedAndUniquified(address[] memory a) internal pure returns (bool result) {
        result = isSortedAndUniquified(_toUints(a));
    }

    /// @dev Returns the sorted set difference of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _difference(a, b, 0);
    }

    /// @dev Returns the sorted set difference between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_difference(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set difference between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function difference(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_difference(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _intersection(a, b, 0);
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_intersection(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function intersection(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_intersection(_toUints(a), _toUints(b), 0));
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(uint256[] memory a, uint256[] memory b)
        internal
        pure
        returns (uint256[] memory c)
    {
        c = _union(a, b, 0);
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(int256[] memory a, int256[] memory b)
        internal
        pure
        returns (int256[] memory c)
    {
        c = _toInts(_union(_toUints(a), _toUints(b), 1 << 255));
    }

    /// @dev Returns the sorted set union between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function union(address[] memory a, address[] memory b)
        internal
        pure
        returns (address[] memory c)
    {
        c = _toAddresses(_union(_toUints(a), _toUints(b), 0));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(int256[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an uint256 array.
    function _toUints(address[] memory a) private pure returns (uint256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            // As any address written to memory will have the upper 96 bits
            // of the word zeroized (as per Solidity spec), we can directly
            // compare these addresses as if they are whole uint256 words.
            casted := a
        }
    }

    /// @dev Reinterpret cast to an int array.
    function _toInts(uint256[] memory a) private pure returns (int256[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Reinterpret cast to an address array.
    function _toAddresses(uint256[] memory a) private pure returns (address[] memory casted) {
        /// @solidity memory-safe-assembly
        assembly {
            casted := a
        }
    }

    /// @dev Converts an array of signed integers to unsigned
    /// integers suitable for sorting or vice versa.
    function _flipSign(int256[] memory a) private pure {
        /// @solidity memory-safe-assembly
        assembly {
            let w := shl(255, 1)
            for { let end := add(a, shl(5, mload(a))) } iszero(eq(a, end)) {} {
                a := add(a, 0x20)
                mstore(a, add(mload(a), w))
            }
        }
    }

    /// @dev Returns whether `a` contains `needle`, and the index of `needle`.
    /// `index` precedence: equal to > nearest before > nearest after.
    function _searchSorted(uint256[] memory a, uint256 needle, uint256 signed)
        private
        pure
        returns (bool found, uint256 index)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let w := not(0)
            let l := 1
            let h := mload(a)
            let t := 0
            for { needle := add(signed, needle) } 1 {} {
                index := shr(1, add(l, h))
                t := add(signed, mload(add(a, shl(5, index))))
                if or(gt(l, h), eq(t, needle)) { break }
                // Decide whether to search the left or right half.
                if iszero(gt(needle, t)) {
                    h := add(index, w)
                    continue
                }
                l := add(index, 1)
            }
            // `index` will be zero in the case of an empty array,
            // or when the value is less than the smallest value in the array.
            found := eq(t, needle)
            t := iszero(iszero(index))
            index := mul(add(index, w), t)
            found := and(found, t)
        }
    }

    /// @dev Returns the sorted set difference of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _difference(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    b := add(b, s)
                    continue
                }
                k := add(k, s)
                mstore(k, u)
                a := add(a, s)
            }
            for {} iszero(gt(a, aEnd)) {} {
                k := add(k, s)
                mstore(k, mload(a))
                a := add(a, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }

    /// @dev Returns the sorted set intersection between `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _intersection(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    b := add(b, s)
                    continue
                }
                a := add(a, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }

    /// @dev Returns the sorted set union of `a` and `b`.
    /// Note: Behaviour is undefined if inputs are not sorted and uniquified.
    function _union(uint256[] memory a, uint256[] memory b, uint256 signed)
        private
        pure
        returns (uint256[] memory c)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let s := 0x20
            let aEnd := add(a, shl(5, mload(a)))
            let bEnd := add(b, shl(5, mload(b)))
            c := mload(0x40) // Set `c` to the free memory pointer.
            a := add(a, s)
            b := add(b, s)
            let k := c
            for {} iszero(or(gt(a, aEnd), gt(b, bEnd))) {} {
                let u := mload(a)
                let v := mload(b)
                if iszero(xor(u, v)) {
                    k := add(k, s)
                    mstore(k, u)
                    a := add(a, s)
                    b := add(b, s)
                    continue
                }
                if iszero(lt(add(u, signed), add(v, signed))) {
                    k := add(k, s)
                    mstore(k, v)
                    b := add(b, s)
                    continue
                }
                k := add(k, s)
                mstore(k, u)
                a := add(a, s)
            }
            for {} iszero(gt(a, aEnd)) {} {
                k := add(k, s)
                mstore(k, mload(a))
                a := add(a, s)
            }
            for {} iszero(gt(b, bEnd)) {} {
                k := add(k, s)
                mstore(k, mload(b))
                b := add(b, s)
            }
            mstore(c, shr(5, sub(k, c))) // Store the length of `c`.
            mstore(0x40, add(k, s)) // Allocate the memory for `c`.
        }
    }
}

/**
 * @title TrustManager
 * @author rhinestone | zeroknots.eth, Konrad Kopp (@kopy-kat)
 * Implements EIP-7484 to query attestations stored in the registry.
 * @dev This contract is abstract and provides utility functions to query attestations.
 */
abstract contract TrustManager is IRegistry, TrustManagerExternalAttesterList {
    using ModuleTypeLib for PackedModuleTypes;
    using LibSort for address[];

    // packed struct to allow for efficient storage.
    // if only one attester is trusted, it only requires 1 SLOAD

    struct TrustedAttesters {
        uint8 attesterCount;
        uint8 threshold;
        address attester;
        mapping(address attester => address linkedAttester) linkedAttesters;
    }

    mapping(address account => TrustedAttesters attesters) internal _accountToAttester;

    // Deliberately using memory here, so we can sort the array
    function trustAttesters(uint8 threshold, address[] memory attesters) external {
        uint256 attestersLength = attesters.length;
        attesters.sort();
        attesters.uniquifySorted();
        if (attestersLength == 0) revert InvalidTrustedAttesterInput();
        if (attesters.length != attestersLength) revert InvalidTrustedAttesterInput();
        // sort attesters

        TrustedAttesters storage _att = _accountToAttester[msg.sender];
        // threshold cannot be greater than the number of attesters
        if (threshold > attestersLength) {
            threshold = uint8(attestersLength);
        }
        //
        _att.attesterCount = uint8(attestersLength);
        _att.threshold = threshold;
        _att.attester = attesters[0];

        attestersLength--;
        for (uint256 i; i < attestersLength; i++) {
            address _attester = attesters[i];
            // user could have set attester to address(0)
            if (_attester == ZERO_ADDRESS) revert InvalidTrustedAttesterInput();
            _att.linkedAttesters[_attester] = attesters[i + 1];
        }
        emit NewTrustedAttesters();
    }

    function check(address module) external view {
        _check(msg.sender, module, ZERO_MODULE_TYPE);
    }

    function checkForAccount(address smartAccount, address module) external view {
        _check(smartAccount, module, ZERO_MODULE_TYPE);
    }

    function check(address module, ModuleType moduleType) external view {
        _check(msg.sender, module, moduleType);
    }

    function checkForAccount(
        address smartAccount,
        address module,
        ModuleType moduleType
    )
        external
        view
    {
        _check(smartAccount, module, moduleType);
    }

    function _check(address smartAccount, address module, ModuleType moduleType) internal view {
        TrustedAttesters storage trustedAttesters = _accountToAttester[smartAccount];
        // SLOAD from one slot
        uint256 attesterCount = trustedAttesters.attesterCount;
        uint256 threshold = trustedAttesters.threshold;
        address attester = trustedAttesters.attester;

        // smart account has no trusted attesters set
        if (attester == ZERO_ADDRESS && threshold != 0) {
            revert NoTrustedAttestersFound();
        }
        // smart account only has ONE trusted attester
        // use this condition to save gas
        else if (threshold == 1) {
            AttestationRecord storage record =
                _getAttestation({ module: module, attester: attester });
            _requireValidAttestation(moduleType, record);
        }
        // smart account has more than one trusted attester
        else {
            // loop though list and check if the attestation is valid
            AttestationRecord storage record =
                _getAttestation({ module: module, attester: attester });
            _requireValidAttestation(moduleType, record);
            for (uint256 i = 1; i < attesterCount; i++) {
                threshold--;
                // get next attester from linked List
                attester = trustedAttesters.linkedAttesters[attester];
                record = _getAttestation({ module: module, attester: attester });
                _requireValidAttestation(moduleType, record);
                // if threshold reached, exit loop
                if (threshold == 0) return;
            }
        }
    }

    /**
     * Check that attestationRecord is valid:
     *                 - not revoked
     *                 - not expired
     *                 - correct module type (if not ZERO_MODULE_TYPE)
     */
    function _requireValidAttestation(
        ModuleType expectedType,
        AttestationRecord storage record
    )
        internal
        view
    {
        // cache values TODO:: assembly to ensure single SLOAD
        uint256 attestedAt = record.time;
        uint256 expirationTime = record.expirationTime;
        uint256 revocationTime = record.revocationTime;
        PackedModuleTypes packedModuleType = record.moduleTypes;

        // check if any attestation was made
        if (attestedAt == ZERO_TIMESTAMP) {
            revert AttestationNotFound();
        }

        // check if attestation has expired
        if (expirationTime != ZERO_TIMESTAMP && block.timestamp > expirationTime) {
            revert AttestationNotFound();
        }

        // check if attestation has been revoked
        if (revocationTime != ZERO_TIMESTAMP) {
            revert RevokedAttestation(record.attester);
        }
        // if a expectedType is set, check if the attestation is for the correct module type
        // if no expectedType is set, module type is not checked
        if (expectedType != ZERO_MODULE_TYPE && !packedModuleType.isType(expectedType)) {
            revert InvalidModuleType();
        }
    }

    function getTrustedAttesters(address smartAccount)
        public
        view
        returns (address[] memory attesters)
    {
        TrustedAttesters storage trustedAttesters = _accountToAttester[smartAccount];
        uint256 count = trustedAttesters.attesterCount;
        attesters = new address[](count);
        attesters[0] = trustedAttesters.attester;

        for (uint256 i = 1; i < count; i++) {
            // get next attester from linked List
            attesters[i] = trustedAttesters.linkedAttesters[attesters[i - 1]];
        }
    }
}

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev We skip the first byte as it's a STOP opcode,
    /// which ensures the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, DATA_OFFSET)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 dataSize | PUSH2 dataSize  | dataSize                |                     |
             * 80          | DUP1            | dataSize dataSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa dataSize dataSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa dataSize dataSize |                     |
             * 39          | CODECOPY        | dataSize                | [0..dataSize): code |
             * 3D          | RETURNDATASIZE  | 0 dataSize              | [0..dataSize): code |
             * F3          | RETURN          |                         | [0..dataSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
                // The actual EVM limit may be smaller and may change over time.
                add(data, gt(dataSize, 0xffff)),
                // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                or(0xfd61000080600a3d393df300, shl(0x40, dataSize))
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Writes `data` into the bytecode of a storage contract with `salt`
    /// and returns its deterministic address.
    function writeDeterministic(bytes memory data, bytes32 salt)
        internal
        returns (address pointer)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            mstore(
                // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
                // The actual EVM limit may be smaller and may change over time.
                add(data, gt(dataSize, 0xffff)),
                // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                or(0xfd61000080600a3d393df300, shl(0x40, dataSize))
            )

            // Deploy a new contract with the generated creation code.
            pointer := create2(0, add(data, 0x15), add(dataSize, 0xa), salt)

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the initialization code hash of the storage contract for `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(bytes memory data) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)
            let dataSize := add(originalDataLength, DATA_OFFSET)

            // Do a out-of-gas revert if `dataSize` is more than 2 bytes.
            // The actual EVM limit may be smaller and may change over time.
            returndatacopy(returndatasize(), returndatasize(), shr(16, dataSize))

            mstore(data, or(0x61000080600a3d393df300, shl(0x40, dataSize)))

            hash := keccak256(add(data, 0x15), add(dataSize, 0xa))

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /// @dev Returns the address of the storage contract for `data`
    /// deployed with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(data);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, DATA_OFFSET)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), DATA_OFFSET, size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + DATA_OFFSET` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, DATA_OFFSET))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where
            // `end + DATA_OFFSET` or `start + DATA_OFFSET` overflows.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }
}

library AttestationLib {
    // The hash of the data type used to relay calls to the attest function. It's the value of
    bytes32 internal constant ATTEST_TYPEHASH =
        keccak256("AttestationRequest(address,uint48,bytes,uint32[])");

    // The hash of the data type used to relay calls to the revoke function. It's the value of
    bytes32 internal constant REVOKE_TYPEHASH = keccak256("RevocationRequest(address)");

    function sload2(AttestationDataRef dataPointer) internal view returns (bytes memory data) {
        data = SSTORE2.read(AttestationDataRef.unwrap(dataPointer));
    }

    function sstore2(
        AttestationRequest calldata request,
        bytes32 salt
    )
        internal
        returns (AttestationDataRef dataPointer)
    {
        /**
         * @dev We are using CREATE2 to deterministically generate the address of the attestation data.
         * Checking if an attestation pointer already exists, would cost more GAS in the average case.
         */
        dataPointer = AttestationDataRef.wrap(SSTORE2.writeDeterministic(request.data, salt));
    }

    function sstore2Salt(address attester, address module) internal view returns (bytes32 salt) {
        salt = keccak256(abi.encodePacked(attester, module, block.timestamp, block.chainid));
    }

    function hash(
        AttestationRequest calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        _hash = keccak256(abi.encode(ATTEST_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }

    function hash(
        AttestationRequest[] calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        _hash = keccak256(abi.encode(ATTEST_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }

    function hash(
        RevocationRequest calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        // TODO: check if this is correct
        _hash = keccak256(abi.encode(REVOKE_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }

    function hash(
        RevocationRequest[] calldata data,
        uint256 nonce
    )
        internal
        pure
        returns (bytes32 _hash)
    {
        // TODO: check if this is correct
        _hash = keccak256(abi.encode(REVOKE_TYPEHASH, keccak256(abi.encode(data)), nonce));
    }
}

/**
 * AttestationManager handles the registry's internal storage of new attestations and revocation of attestation
 * @dev This contract is abstract and provides utility functions to store attestations and revocations.
 */
abstract contract AttestationManager is IRegistry, ModuleManager, SchemaManager, TrustManager {
    using StubLib for *;
    using AttestationLib for AttestationDataRef;
    using AttestationLib for AttestationRequest;
    using AttestationLib for AttestationRequest[];
    using AttestationLib for address;
    using ModuleTypeLib for ModuleType[];

    mapping(address module => mapping(address attester => AttestationRecord attestation)) internal
        _moduleToAttesterToAttestations;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      Attestation                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Processes an attestation request and stores the attestation in the registry.
     * If the attestation was made for a module that was not registered, the function will revert.
     * function will get the external Schema Validator for the supplied SchemaUID
     *         and call it, if an external IExternalSchemaValidator was set
     * function will get the external IExternalResolver for the module - that the attestation is for
     *        and call it, if an external Resolver was set
     */
    function _attest(
        address attester,
        SchemaUID schemaUID,
        AttestationRequest calldata request
    )
        internal
    {
        (AttestationRecord memory record, ResolverUID resolverUID) =
            _storeAttestation({ schemaUID: schemaUID, attester: attester, request: request });

        record.requireExternalSchemaValidation({ schema: schemas[schemaUID] });
        record.requireExternalResolverOnAttestation({ resolver: resolvers[resolverUID] });
    }

    /**
     * Processes an array of attestation requests  and stores the attestations in the registry.
     * If the attestation was made for a module that was not registered, the function will revert.
     * function will get the external Schema Validator for the supplied SchemaUID
     *         and call it, if an external IExternalSchemaValidator was set
     * function will get the external IExternalResolver for the module - that the attestation is for
     *        and call it, if an external Resolver was set
     */
    function _attest(
        address attester,
        SchemaUID schemaUID,
        AttestationRequest[] calldata requests
    )
        internal
    {
        uint256 length = requests.length;
        AttestationRecord[] memory records = new AttestationRecord[](length);
        // loop will check that the batched attestation is made ONLY for the same resolver
        ResolverUID resolverUID;
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            // save the attestation record into records array.
            (records[i], resolverUID_cache) = _storeAttestation({
                schemaUID: schemaUID,
                attester: attester,
                request: requests[i]
            });
            // cache the first resolverUID and compare it to the rest
            // If the resolverUID is different, revert
            // @dev if you want to use different resolvers, make different attestation calls
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DifferentResolvers();
        }

        // Use StubLib to call schema Validation and resolver if needed
        records.requireExternalSchemaValidation({ schema: schemas[schemaUID] });
        records.requireExternalResolverOnAttestation({ resolver: resolvers[resolverUID] });
    }

    /**
     * Stores an attestation in the registry storage.
     * The bytes encoded AttestationRequest.Data is not stored directly into the registry storage,
     * but rather stored with SSTORE2. SSTORE2/SLOAD2 is writing and reading contract storage
     * paying a fraction of the cost, it uses contract code as storage, writing data takes the
     * form of contract creations and reading data uses EXTCODECOPY.
     * since attestation data is supposed to be immutable, it is a good candidate for SSTORE2
     *
     * @dev This function will revert if the same module is attested twice by the same attester.
     *      If you want to re-attest, you have to revoke your attestation first, and then attest again.
     *
     * @param attester The address of the attesting account.
     * @param request The AttestationRequest that was supplied via calldata
     * @return record The AttestationRecord of what was written into registry storage
     * @return resolverUID The resolverUID in charge for the module
     */
    function _storeAttestation(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest calldata request
    )
        internal
        returns (AttestationRecord memory record, ResolverUID resolverUID)
    {
        // TODO: what if schema behind schemaUID doesnt exist?
        // Frontrun on L2s?
        uint48 timeNow = _time();
        // Ensure that either no expiration time was set or that it was set in the future.
        if (request.expirationTime != ZERO_TIMESTAMP && request.expirationTime <= timeNow) {
            revert InvalidExpirationTime();
        }
        // caching module address.
        address module = request.moduleAddr;
        // SLOAD the resolverUID from the moduleRecord
        resolverUID = _moduleAddrToRecords[module].resolverUID;
        // Ensure that attestation is for module that was registered.
        if (resolverUID == EMPTY_RESOLVER_UID) {
            revert ModuleNotFoundInRegistry(module);
        }

        // use SSTORE2 to store the data in attestationRequest
        // @dev this will revert, if in a batched attestation,
        // the same data is used twice by the same attester for the same module since the salt will be the same
        AttestationDataRef sstore2Pointer = request.sstore2({ salt: attester.sstore2Salt(module) });

        // write into memory allocated record, since that is the return value
        record = AttestationRecord({
            time: timeNow,
            expirationTime: request.expirationTime,
            revocationTime: uint48(ZERO_TIMESTAMP),
            moduleTypes: request.moduleTypes.packCalldata(),
            schemaUID: schemaUID,
            moduleAddr: module,
            attester: attester,
            dataPointer: sstore2Pointer
        });
        // SSTORE attestation to registry storage
        _moduleToAttesterToAttestations[request.moduleAddr][attester] = record;

        emit Attested(module, attester, schemaUID, sstore2Pointer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       Revocation                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Revoke a single Revocation Request
     * This function will write the RevocationRequest into storage, and get the stored RevocationRecord back,
     * and pass the RevocationRecord to the resolver to check if the revocation is valid
     */
    function _revoke(address attester, RevocationRequest calldata request) internal {
        (AttestationRecord memory record, ResolverUID resolverUID) =
            _storeRevocation(attester, request);
        // TODO: what if this fails? it would stop attesters from revoking. Is this wanted behavior?
        record.requireExternalResolverOnRevocation({ resolver: resolvers[resolverUID] });
    }

    /**
     * Revoke an array Revocation Request
     * This function will write the RevocationRequest into storage, and get the stored RevocationRecord back,
     * and pass the RevocationRecord to the resolver to check if the revocation is valid
     */
    function _revoke(address attester, RevocationRequest[] calldata requests) internal {
        uint256 length = requests.length;
        AttestationRecord[] memory records = new AttestationRecord[](length);
        ResolverUID resolverUID;
        // loop over revocation requests. This function will revert if different resolverUIDs
        // are responsible for the modules that are subject of the revocation. This is to reduce complexity
        // @dev if you want to revoke attestations from different resolvers, make different revocation calls
        for (uint256 i; i < length; i++) {
            ResolverUID resolverUID_cache;
            (records[i], resolverUID_cache) = _storeRevocation(attester, requests[i]);
            if (i == 0) resolverUID = resolverUID_cache;
            else if (resolverUID_cache != resolverUID) revert DifferentResolvers();
        }

        // No schema validation required during revocation. the attestation data was already checked against

        // TODO: what if this fails? it would stop attesters from revoking. Is this wanted behavior?
        records.requireExternalResolverOnRevocation({ resolver: resolvers[resolverUID] });
    }

    /**
     * Gets the AttestationRecord for the supplied RevocationRequest and stores the revocation time in the registry storage
     * @param revoker The address of the attesting account.
     * @param request The AttestationRequest that was supplied via calldata
     * @return record The AttestationRecord of what was written into registry storage
     * @return resolverUID The resolverUID in charge for the module
     */
    function _storeRevocation(
        address revoker,
        RevocationRequest calldata request
    )
        internal
        returns (AttestationRecord memory record, ResolverUID resolverUID)
    {
        AttestationRecord storage attestationStorage =
            _moduleToAttesterToAttestations[request.moduleAddr][revoker];

        // SLOAD entire record. This will later be passed to the resolver
        record = attestationStorage;
        resolverUID = _moduleAddrToRecords[request.moduleAddr].resolverUID;

        // Ensure that we aren't attempting to revoke a non-existing attestation.
        if (record.dataPointer == EMPTY_ATTESTATION_REF) {
            revert AttestationNotFound();
        }

        // Allow only original attesters to revoke their attestations.
        if (record.attester != revoker) {
            revert AccessDenied();
        }

        // Ensure that we aren't trying to revoke the same attestation twice.
        if (record.revocationTime != ZERO_TIMESTAMP) {
            revert AlreadyRevoked();
        }

        // SSTORE revocation time to registry storage
        attestationStorage.revocationTime = _time();
        // set revocation time to NOW
        emit Revoked({ moduleAddr: record.moduleAddr, revoker: revoker, schema: record.schemaUID });
    }

    /**
     * Returns the attestation records for the given module and attesters.
     * This function is expected to be used by TrustManager and TrustManagerExternalAttesterList
     */
    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        override
        returns (AttestationRecord storage)
    {
        return _moduleToAttesterToAttestations[module][attester];
    }
}

abstract contract Attestation is IRegistry, AttestationManager {
    function attest(SchemaUID schemaUID, AttestationRequest calldata request) external {
        _attest(msg.sender, schemaUID, request);
    }

    function attest(SchemaUID schemaUID, AttestationRequest[] calldata requests) external {
        _attest(msg.sender, schemaUID, requests);
    }

    function revoke(RevocationRequest calldata request) external {
        _revoke(msg.sender, request);
    }

    function revoke(RevocationRequest[] calldata requests) external {
        _revoke(msg.sender, requests);
    }

    function findAttestation(
        address module,
        address attester
    )
        external
        view
        returns (AttestationRecord memory attestation)
    {
        attestation = _getAttestation(module, attester);
    }

    function findAttestations(
        address module,
        address[] calldata attesters
    )
        external
        view
        returns (AttestationRecord[] memory attestations)
    {
        uint256 length = attesters.length;
        attestations = new AttestationRecord[](length);
        for (uint256 i; i < length; i++) {
            attestations[i] = _getAttestation(module, attesters[i]);
        }
    }
}

/// @notice Contract for EIP-712 typed structured data hashing and signing.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
///
/// @dev Note, this implementation:
/// - Uses `address(this)` for the `verifyingContract` field.
/// - Does NOT use the optional EIP-712 salt.
/// - Does NOT use any EIP-712 extensions.
/// This is for simplicity and to save gas.
/// If you need to customize, please fork / modify accordingly.
abstract contract EIP712 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  CONSTANTS AND IMMUTABLES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    uint256 private immutable _cachedThis;
    uint256 private immutable _cachedChainId;
    bytes32 private immutable _cachedNameHash;
    bytes32 private immutable _cachedVersionHash;
    bytes32 private immutable _cachedDomainSeparator;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Cache the hashes for cheaper runtime gas costs.
    /// In the case of upgradeable contracts (i.e. proxies),
    /// or if the chain id changes due to a hard fork,
    /// the domain separator will be seamlessly calculated on-the-fly.
    constructor() {
        _cachedThis = uint256(uint160(address(this)));
        _cachedChainId = block.chainid;

        string memory name;
        string memory version;
        if (!_domainNameAndVersionMayChange()) (name, version) = _domainNameAndVersion();
        bytes32 nameHash = _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(name));
        bytes32 versionHash =
            _domainNameAndVersionMayChange() ? bytes32(0) : keccak256(bytes(version));
        _cachedNameHash = nameHash;
        _cachedVersionHash = versionHash;

        bytes32 separator;
        if (!_domainNameAndVersionMayChange()) {
            /// @solidity memory-safe-assembly
            assembly {
                let m := mload(0x40) // Load the free memory pointer.
                mstore(m, _DOMAIN_TYPEHASH)
                mstore(add(m, 0x20), nameHash)
                mstore(add(m, 0x40), versionHash)
                mstore(add(m, 0x60), chainid())
                mstore(add(m, 0x80), address())
                separator := keccak256(m, 0xa0)
            }
        }
        _cachedDomainSeparator = separator;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   FUNCTIONS TO OVERRIDE                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Please override this function to return the domain name and version.
    /// ```
    ///     function _domainNameAndVersion()
    ///         internal
    ///         pure
    ///         virtual
    ///         returns (string memory name, string memory version)
    ///     {
    ///         name = "Solady";
    ///         version = "1";
    ///     }
    /// ```
    ///
    /// Note: If the returned result may change after the contract has been deployed,
    /// you must override `_domainNameAndVersionMayChange()` to return true.
    function _domainNameAndVersion()
        internal
        view
        virtual
        returns (string memory name, string memory version);

    /// @dev Returns if `_domainNameAndVersion()` may change
    /// after the contract has been deployed (i.e. after the constructor).
    /// Default: false.
    function _domainNameAndVersionMayChange() internal pure virtual returns (bool result) {}

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _domainSeparator() internal view virtual returns (bytes32 separator) {
        if (_domainNameAndVersionMayChange()) {
            separator = _buildDomainSeparator();
        } else {
            separator = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) separator = _buildDomainSeparator();
        }
    }

    /// @dev Returns the hash of the fully encoded EIP-712 message for this domain,
    /// given `structHash`, as defined in
    /// https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct.
    ///
    /// The hash can be used together with {ECDSA-recover} to obtain the signer of a message:
    /// ```
    ///     bytes32 digest = _hashTypedData(keccak256(abi.encode(
    ///         keccak256("Mail(address to,string contents)"),
    ///         mailTo,
    ///         keccak256(bytes(mailContents))
    ///     )));
    ///     address signer = ECDSA.recover(digest, signature);
    /// ```
    function _hashTypedData(bytes32 structHash) internal view virtual returns (bytes32 digest) {
        // We will use `digest` to store the domain separator to save a bit of gas.
        if (_domainNameAndVersionMayChange()) {
            digest = _buildDomainSeparator();
        } else {
            digest = _cachedDomainSeparator;
            if (_cachedDomainSeparatorInvalidated()) digest = _buildDomainSeparator();
        }
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    EIP-5267 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev See: https://eips.ethereum.org/EIPS/eip-5267
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        fields = hex"0f"; // `0b01111`.
        (name, version) = _domainNameAndVersion();
        chainId = block.chainid;
        verifyingContract = address(this);
        salt = salt; // `bytes32(0)`.
        extensions = extensions; // `new uint256[](0)`.
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PRIVATE HELPERS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the EIP-712 domain separator.
    function _buildDomainSeparator() private view returns (bytes32 separator) {
        // We will use `separator` to store the name hash to save a bit of gas.
        bytes32 versionHash;
        if (_domainNameAndVersionMayChange()) {
            (string memory name, string memory version) = _domainNameAndVersion();
            separator = keccak256(bytes(name));
            versionHash = keccak256(bytes(version));
        } else {
            separator = _cachedNameHash;
            versionHash = _cachedVersionHash;
        }
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), separator) // Name hash.
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            separator := keccak256(m, 0xa0)
        }
    }

    /// @dev Returns if the cached domain separator has been invalidated.
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        uint256 cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }
}

/// @notice Signature verification helper that supports both ECDSA signatures from EOAs
/// and ERC1271 signatures from smart contract wallets like Argent and Gnosis safe.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SignatureCheckerLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/SignatureChecker.sol)
///
/// @dev Note:
/// - The signature checking functions use the ecrecover precompile (0x1).
/// - The `bytes memory signature` variants use the identity precompile (0x4)
///   to copy memory internally.
/// - Unlike ECDSA signatures, contract signatures are revocable.
/// - As of Solady version 0.0.134, all `bytes signature` variants accept both
///   regular 65-byte `(r, s, v)` and EIP-2098 `(r, vs)` short form signatures.
///   See: https://eips.ethereum.org/EIPS/eip-2098
///   This is for calldata efficiency on smart accounts prevalent on L2s.
///
/// WARNING! Do NOT use signatures as unique identifiers:
/// - Use a nonce in the digest to prevent replay attacks on the same contract.
/// - Use EIP-712 for the digest to prevent replay attacks across different chains and contracts.
///   EIP-712 also enables readable signing of typed data for better user safety.
/// This implementation does NOT check if a signature is non-malleable.
library SignatureCheckerLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*               SIGNATURE CHECKING OPERATIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x40, mload(add(signature, 0x20))) // `r`.
                if eq(mload(signature), 64) {
                    let vs := mload(add(signature, 0x40))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                if eq(mload(signature), 65) {
                    mstore(0x20, byte(0, mload(add(signature, 0x60)))) // `v`.
                    mstore(0x60, mload(add(signature, 0x40))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                // Copy the `signature` over.
                let n := add(0x20, mload(signature))
                pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(returndatasize(), 0x44), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether `signature` is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNowCalldata(address signer, bytes32 hash, bytes calldata signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                if eq(signature.length, 64) {
                    let vs := calldataload(add(signature.offset, 0x20))
                    mstore(0x20, add(shr(255, vs), 27)) // `v`.
                    mstore(0x40, calldataload(signature.offset)) // `r`.
                    mstore(0x60, shr(1, shl(1, vs))) // `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                if eq(signature.length, 65) {
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40)))) // `v`.
                    calldatacopy(0x40, signature.offset, 0x40) // `r`, `s`.
                    let t :=
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            1, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x01, // Start of output.
                            0x20 // Size of output.
                        )
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                        isValid := 1
                        mstore(0x60, 0) // Restore the zero slot.
                        mstore(0x40, m) // Restore the free memory pointer.
                        break
                    }
                }
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), signature.length)
                // Copy the `signature` over.
                calldatacopy(add(m, 0x64), signature.offset, signature.length)
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        add(signature.length, 0x64), // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                break
            }
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, add(shr(255, vs), 27)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, shr(1, shl(1, vs))) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), mload(0x60)) // `s`.
                mstore8(add(m, 0xa4), mload(0x20)) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `signer` and `hash`.
    /// If `signer` is a smart contract, the signature is validated with ERC1271.
    /// Otherwise, the signature is validated with `ECDSA.recover`.
    function isValidSignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits of `signer` in case they are dirty.
            for { signer := shr(96, shl(96, signer)) } signer {} {
                let m := mload(0x40)
                mstore(0x00, hash)
                mstore(0x20, and(v, 0xff)) // `v`.
                mstore(0x40, r) // `r`.
                mstore(0x60, s) // `s`.
                let t :=
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        1, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x01, // Start of output.
                        0x20 // Size of output.
                    )
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                if iszero(or(iszero(returndatasize()), xor(signer, mload(t)))) {
                    isValid := 1
                    mstore(0x60, 0) // Restore the zero slot.
                    mstore(0x40, m) // Restore the free memory pointer.
                    break
                }

                let f := shl(224, 0x1626ba7e)
                mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
                mstore(add(m, 0x04), hash)
                let d := add(m, 0x24)
                mstore(d, 0x40) // The offset of the `signature` in the calldata.
                mstore(add(m, 0x44), 65) // Length of the signature.
                mstore(add(m, 0x64), r) // `r`.
                mstore(add(m, 0x84), s) // `s`.
                mstore8(add(m, 0xa4), v) // `v`.
                // forgefmt: disable-next-item
                isValid := and(
                    // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                    eq(mload(d), f),
                    // Whether the staticcall does not revert.
                    // This must be placed at the end of the `and` clause,
                    // as the arguments are evaluated from right to left.
                    staticcall(
                        gas(), // Remaining gas.
                        signer, // The `signer` address.
                        m, // Offset of calldata in memory.
                        0xa5, // Length of calldata in memory.
                        d, // Offset of returndata.
                        0x20 // Length of returndata to write.
                    )
                )
                mstore(0x60, 0) // Restore the zero slot.
                mstore(0x40, m) // Restore the free memory pointer.
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     ERC1271 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            // Copy the `signature` over.
            let n := add(0x20, mload(signature))
            pop(staticcall(gas(), 4, signature, n, add(m, 0x44), n))
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(returndatasize(), 0x44), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether `signature` is valid for `hash` for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNowCalldata(
        address signer,
        bytes32 hash,
        bytes calldata signature
    ) internal view returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), signature.length)
            // Copy the `signature` over.
            calldatacopy(add(m, 0x64), signature.offset, signature.length)
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    add(signature.length, 0x64), // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`r`, `vs`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), shr(1, shl(1, vs))) // `s`.
            mstore8(add(m, 0xa4), add(shr(255, vs), 27)) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /// @dev Returns whether the signature (`v`, `r`, `s`) is valid for `hash`
    /// for an ERC1271 `signer` contract.
    function isValidERC1271SignatureNow(address signer, bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40)
            let f := shl(224, 0x1626ba7e)
            mstore(m, f) // `bytes4(keccak256("isValidSignature(bytes32,bytes)"))`.
            mstore(add(m, 0x04), hash)
            let d := add(m, 0x24)
            mstore(d, 0x40) // The offset of the `signature` in the calldata.
            mstore(add(m, 0x44), 65) // Length of the signature.
            mstore(add(m, 0x64), r) // `r`.
            mstore(add(m, 0x84), s) // `s`.
            mstore8(add(m, 0xa4), v) // `v`.
            // forgefmt: disable-next-item
            isValid := and(
                // Whether the returndata is the magic value `0x1626ba7e` (left-aligned).
                eq(mload(d), f),
                // Whether the staticcall does not revert.
                // This must be placed at the end of the `and` clause,
                // as the arguments are evaluated from right to left.
                staticcall(
                    gas(), // Remaining gas.
                    signer, // The `signer` address.
                    m, // Offset of calldata in memory.
                    0xa5, // Length of calldata in memory.
                    d, // Offset of returndata.
                    0x20 // Length of returndata to write.
                )
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, hash) // Store into scratch space for keccak256.
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32") // 28 bytes.
            result := keccak256(0x04, 0x3c) // `32 * 2 - (32 - 28) = 60 = 0x3c`.
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    /// Note: Supports lengths of `s` up to 999999 bytes.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            let sLength := mload(s)
            let o := 0x20
            mstore(o, "\x19Ethereum Signed Message:\n") // 26 bytes, zero-right-padded.
            mstore(0x00, 0x00)
            // Convert the `s.length` to ASCII decimal representation: `base10(s.length)`.
            for { let temp := sLength } 1 {} {
                o := sub(o, 1)
                mstore8(o, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            let n := sub(0x3a, o) // Header length: `26 + 32 - o`.
            // Throw an out-of-offset error (consumes all gas) if the header exceeds 32 bytes.
            returndatacopy(returndatasize(), returndatasize(), gt(n, 0x20))
            mstore(s, or(mload(0x00), mload(n))) // Temporarily store the header.
            result := keccak256(add(s, sub(0x20, n)), add(n, sLength))
            mstore(s, sLength) // Restore the length.
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes.
    function emptySignature() internal pure returns (bytes calldata signature) {
        /// @solidity memory-safe-assembly
        assembly {
            signature.length := 0
        }
    }
}

contract SignedAttestation is IRegistry, Attestation, EIP712 {
    using AttestationLib for AttestationRequest;
    using AttestationLib for RevocationRequest;
    using AttestationLib for AttestationRequest[];
    using AttestationLib for RevocationRequest[];

    mapping(address attester => uint256 nonce) public attesterNonce;

    /**
     * Attestation can be made on any SchemaUID.
     * @dev the registry, will forward your AttestationRequest.Data to the SchemaManager to
     * check if the schema exists.
     * @param schemaUID The SchemaUID of the schema to be attested.
     */
    function attest(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest calldata request,
        bytes calldata signature
    )
        external
    {
        // verify signature
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(request.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _attest(attester, schemaUID, request);
    }

    function attest(
        SchemaUID schemaUID,
        address attester,
        AttestationRequest[] calldata requests,
        bytes calldata signature
    )
        external
    {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(requests.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _attest(attester, schemaUID, requests);
    }

    function revoke(
        address attester,
        RevocationRequest calldata request,
        bytes calldata signature
    )
        external
    {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(request.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _revoke(attester, request);
    }

    function revoke(
        address attester,
        RevocationRequest[] calldata requests,
        bytes calldata signature
    )
        external
    {
        uint256 nonce = ++attesterNonce[attester];
        bytes32 digest = _hashTypedData(requests.hash(nonce));
        bool valid = SignatureCheckerLib.isValidSignatureNow(attester, digest, signature);
        if (!valid) revert InvalidSignature();

        _revoke(attester, requests);
    }

    function _domainNameAndVersion()
        internal
        view
        virtual
        override
        returns (string memory name, string memory version)
    {
        name = "RhinestoneRegistry";
        version = "v1.0";
    }

    function getDigest(
        AttestationRequest calldata request,
        address attester
    )
        external
        view
        returns (bytes32)
    {
        return _hashTypedData(request.hash(attesterNonce[attester] + 1));
    }

    function getDigest(
        AttestationRequest[] calldata requests,
        address attester
    )
        external
        view
        returns (bytes32)
    {
        return _hashTypedData(requests.hash(attesterNonce[attester] + 1));
    }

    function getDigest(
        RevocationRequest calldata request,
        address attester
    )
        external
        view
        returns (bytes32)
    {
        return _hashTypedData(request.hash(attesterNonce[attester] + 1));
    }

    function getDigest(
        RevocationRequest[] calldata requests,
        address attester
    )
        external
        view
        returns (bytes32)
    {
        return _hashTypedData(requests.hash(attesterNonce[attester] + 1));
    }
}

/**
 * @author zeroknots
 */

contract Registry is IRegistry, SignedAttestation { }

