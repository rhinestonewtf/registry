contract MockERC1271Attester {
    bool immutable returnVal;

    constructor(bool ret) {
        returnVal = ret;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view returns (bytes4) {
        if (returnVal) return this.isValidSignature.selector;
        else return 0x0000000;
    }
}
