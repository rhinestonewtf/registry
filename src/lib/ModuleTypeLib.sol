// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ModuleTypesEncoded } from "../DataTypes.sol";

library ModuleTypeLib {
    error InvalidType(ModuleTypesEncoded encodedType);

    function isPrime(uint256 n) public view returns (bool) {
        if (n < 2) {
            return false;
        }
        if (n == 2) {
            return true;
        }
        return expmod(2, n - 1, n) == 1;
    }

    // use precompile expmod to calculate modular exponentiation
    // https://gist.github.com/lhartikk/09e3a1ef1d8701e258fc91c19bc9e02f
    function expmod(uint256 base, uint256 e, uint256 m) internal view returns (uint256 o) {
        assembly {
            // define pointer
            let p := mload(0x40)
            // store data assembly-favouring ways
            mstore(p, 0x20) // Length of Base
            mstore(add(p, 0x20), 0x20) // Length of Exponent
            mstore(add(p, 0x40), 0x20) // Length of Modulus
            mstore(add(p, 0x60), base) // Base
            mstore(add(p, 0x80), e) // Exponent
            mstore(add(p, 0xa0), m) // Modulus
            if iszero(staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)) { revert(0, 0) }
            // data
            o := mload(p)
        }
    }

    function encType(uint8[] calldata types)
        internal
        view
        returns (ModuleTypesEncoded encodedType)
    {
        uint32 typeRaw = 1;
        uint256 length = types.length;
        if (length == 0) revert();
        for (uint8 i = 0; i < length; i++) {
            if (!isPrime(types[i])) revert();
            typeRaw = typeRaw * types[i];
        }
        encodedType = ModuleTypesEncoded.wrap(typeRaw);
    }

    function checkType(
        ModuleTypesEncoded encodedType,
        uint256 check
    )
        internal
        view
        returns (bool)
    {
        if (!isPrime(check)) return false;
        if (ModuleTypesEncoded.unwrap(encodedType) % check != 0) return false;
        return true;
    }

    function checkType(
        ModuleTypesEncoded encodedType,
        uint256[] memory check
    )
        internal
        view
        returns (bool)
    {
        uint256 length = check.length;
        for (uint256 i; i < length; i++) {
            if (!checkType(encodedType, check[i])) return false;
        }
        return true;
    }
}
