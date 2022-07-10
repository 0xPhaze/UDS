// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967Versioned, DIAMOND_STORAGE_ERC1967_UPGRADE} from "./ERC1967Versioned.sol";

// ------------- Errors

error InvalidUUID();
error InvalidOwner();
error NotAContract();
error InvalidUpgradeVersion();

/// @notice ERC1967Proxy with version control
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967Versioned {
    constructor(address logic, bytes memory data) payable {
        _upgradeToAndCall(logic, data);
    }

    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(gas(), sload(DIAMOND_STORAGE_ERC1967_UPGRADE), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch success
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
