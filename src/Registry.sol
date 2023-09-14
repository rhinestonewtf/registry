// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./base/Schema.sol";
import "./base/Attestation.sol";
import "./base/Module.sol";
import "./base/Query.sol";

/**
 * @author zeroknots
 */
contract Registry is Schema, Query, Attestation, Module {
    constructor(
        Yaho _yaho,
        Yaru _yaru,
        address _l1registry,
        string memory name,
        string memory version
    )
        Attestation(_yaho, _yaru, _l1registry, name, version)
    { }

    /*//////////////////////////////////////////////////////////////
                            Helper Functions
    //////////////////////////////////////////////////////////////*/

    // @TODO
    function setResolver(bytes32 uid, ISchemaResolver resolver) external override { }

    function getSchema(bytes32 uid)
        public
        view
        override(Attestation, Schema)
        returns (SchemaRecord memory)
    {
        return super.getSchema(uid);
    }

    function _getAttestation(
        address module,
        address attester
    )
        internal
        view
        virtual
        override(Attestation, Query)
        returns (AttestationRecord storage)
    {
        return super._getAttestation(module, attester);
    }

    function getSchemaResolver(bytes32 uid)
        public
        view
        virtual
        override(Attestation, Module, Schema)
        returns (SchemaResolver memory)
    {
        return super.getSchemaResolver(uid);
    }

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        override(Attestation, Module)
        returns (ModuleRecord storage)
    {
        return super._getModule(moduleAddress);
    }
}
