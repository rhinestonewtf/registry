// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import "./base/RSSchema.sol";
import "./base/RSAttestation.sol";
import "./base/RSModule.sol";
import "./base/RSQuery.sol";

/**
 * @author zeroknots
 */
contract RhinestoneRegistry is RSSchema, RSQuery, RSAttestation, RSModule {
    constructor(
        Yaho _yaho,
        Yaru _yaru,
        address _l1registry,
        string memory name,
        string memory version
    )
        RSAttestation(_yaho, _yaru, _l1registry, name, version)
    { }

    /*//////////////////////////////////////////////////////////////
                            Helper Functions
    //////////////////////////////////////////////////////////////*/

    function getBridges(bytes32 uid)
        public
        view
        override(RSAttestation, RSSchema)
        returns (address[] memory)
    {
        return super.getBridges(uid);
    }

    function getSchema(bytes32 uid)
        public
        view
        override(RSAttestation, RSModule, RSSchema)
        returns (SchemaRecord memory)
    {
        return super.getSchema(uid);
    }

    function _getAttestation(
        address module,
        address authority
    )
        internal
        view
        virtual
        override(RSAttestation, RSQuery)
        returns (bytes32)
    {
        return super._getAttestation(module, authority);
    }

    function _getAttestation(bytes32 attestationId)
        internal
        view
        virtual
        override
        returns (Attestation storage)
    {
        return _attestations[attestationId];
    }

    function _getModule(address moduleAddress)
        internal
        view
        virtual
        override(RSAttestation, RSModule)
        returns (Module storage)
    {
        return super._getModule(moduleAddress);
    }
}
