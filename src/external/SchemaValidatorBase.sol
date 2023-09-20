// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISchemaValidator.sol";

contract SchemaValidatorBase is ISchemaValidator {
    function validateSchema(AttestationRequestData calldata attestation)
        external
        view
        virtual
        override
        returns (bool)
    { }

    function validateSchema(AttestationRequestData[] calldata attestations)
        external
        view
        virtual
        override
        returns (bool)
    { }

    function supportsInterface(bytes4 interfaceID) external view virtual returns (bool) {
        return interfaceID == this.supportsInterface.selector;
    }
}
