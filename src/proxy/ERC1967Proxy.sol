// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
bytes32 constant DIAMOND_STORAGE_ERC1967_UPGRADE = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ERC1967_UPGRADE } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

/// @notice ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        if (logic.code.length == 0) revert NotAContract();

        bytes32 uuid = ERC1822(logic).proxiableUUID();

        if (uuid != DIAMOND_STORAGE_ERC1967_UPGRADE) revert InvalidUUID();

        emit Upgraded(logic);

        if (data.length != 0) {
            (bool success, bytes memory returndata) = logic.delegatecall(data);

            if (!success) {
                assembly {
                    let returndata_size := mload(returndata)

                    revert(add(32, returndata), returndata_size)
                }
            }
        }

        s().implementation = logic;
    }
}

/// @notice Minimal ERC1967Proxy
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ERC1967Proxy is ERC1967 {
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

/// @notice ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}
