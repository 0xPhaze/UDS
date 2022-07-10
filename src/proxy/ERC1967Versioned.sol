// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1822Versioned} from "./ERC1822Versioned.sol";

// ------------- Storage

// keccak256("eip1967.proxy.implementation") - 1 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
bytes32 constant DIAMOND_STORAGE_ERC1967_UPGRADE = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967VersionedUpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ERC1967_UPGRADE } // prettier-ignore
}

struct ERC1967VersionedUpgradeDS {
    address implementation;
    uint256 version;
}

// ------------- Errors

error InvalidUUID();
error InvalidOwner();
error NotAContract();
error InvalidUpgradeVersion();

/// @notice ERC1967 with version control
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967Versioned {
    event Upgraded(address indexed implementation, uint256 indexed version);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        bytes32 uuid = IERC1822Versioned(logic).proxiableUUID();
        uint256 newVersion = IERC1822Versioned(logic).proxiableVersion();

        if (s().version >= newVersion) revert InvalidUpgradeVersion();
        if (uuid != DIAMOND_STORAGE_ERC1967_UPGRADE) revert InvalidUUID();

        emit Upgraded(logic, newVersion);

        if (data.length != 0) {
            (bool success, bytes memory returndata) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            }
        }

        s().version = newVersion;
        s().implementation = logic;
    }
}
