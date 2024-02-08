// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { ResolverRecord, SchemaRecord, SchemaUID, ResolverUID } from "../DataTypes.sol";

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
