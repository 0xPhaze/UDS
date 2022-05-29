// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1822Versioned {
    function proxiableVersion() external view returns (uint256);

    function proxiableUUID() external view returns (bytes32);
}

abstract contract ERC1822Versioned is IERC1822Versioned {
    function proxiableVersion() public view virtual returns (uint256);
}
