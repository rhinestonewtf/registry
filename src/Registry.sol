// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { Schema } from "./base/Schema.sol";
import { AttestationDelegation } from "./base/AttestationDelegation.sol";
import { Attestation, AttestationResolve } from "./base/Attestation.sol";
import { Module } from "./base/Module.sol";
import { Query } from "./base/QueryAttester.sol";
import {
    AttestationRecord,
    SchemaUID,
    SchemaRecord,
    ResolverRecord,
    ResolverUID,
    ModuleRecord
} from "./DataTypes.sol";

/**
 * @author zeroknots
 */
contract Registry is Schema, Query, AttestationDelegation, Module {
    constructor() { }

    /*//////////////////////////////////////////////////////////////
                            Helper Functions
    //////////////////////////////////////////////////////////////*/

    function getSchema(SchemaUID uid) public view override(Schema) returns (SchemaRecord memory) {
        return super.getSchema(uid);
    }

    function _getSchema(SchemaUID uid)
        internal
        view
        override(AttestationResolve, Schema)
        returns (SchemaRecord storage)
    {
        return super._getSchema({ schemaUID: uid });
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

    function getResolver(ResolverUID uid)
        public
        view
        virtual
        override(AttestationResolve, Module, Schema)
        returns (ResolverRecord memory)
    {
        return super.getResolver(uid);
    }

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        override(AttestationResolve, Module)
        returns (ModuleRecord storage)
    {
        return super._getModule(moduleAddress);
    }
}
