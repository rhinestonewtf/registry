import "forge-std/Test.sol";

type ModuleType is uint8;

contract Prime {
    error InvalidType(uint16 encodedType);

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

    function encType(uint8[] memory types) internal view returns (uint16 encodedType) {
        encodedType = 1;
        for (uint8 i = 0; i < types.length; i++) {
            if (!isPrime(types[i])) revert();
            encodedType = encodedType * types[i];
        }
    }

    function checkType(uint16 encodedType, uint256 check) internal pure {
        if (encodedType % check != 0) revert InvalidType(encodedType);
    }

    function checkType(uint16 encodedType, uint256[] memory check) internal pure {
        uint256 length = check.length;
        for (uint256 i; i < length; i++) {
            checkType(encodedType, check[i]);
        }
    }
}

contract TypeTest is Test, Prime {
    uint8 typeInt;

    function setUp() public { }

    function test_writeType() public {
        uint8[] memory types = new uint8[](2);
        types[0] = 5;
        types[1] = 3;

        uint16 encodedType = encType(types);
        assertEq(encodedType, 15);

        checkType(encodedType, 3);
        checkType(encodedType, 5);
        // checkType(encodedType, 6);
        // checkType(encodedType, 7);
    }
}
