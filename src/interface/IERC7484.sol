// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IERC7484 {
    function check(address module, address attester) external view returns (uint256 attestedAt);
    function checkN(
        address module,
        address[] memory attesters,
        uint256 threshold
    )
        external
        view
        returns (uint256[] memory attestedAtArray);
}
