// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("eip1967.proxy.implementation") - 1 = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
bytes32 constant ERC1967_PROXY_STORAGE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

function s() pure returns (ERC1967UpgradeDS storage diamondStorage) {
    assembly { diamondStorage.slot := ERC1967_PROXY_STORAGE_SLOT } // prettier-ignore
}

struct ERC1967UpgradeDS {
    address implementation;
}

// ------------- errors

error InvalidUUID();
error NotAContract();

import "forge-std/console.sol";

// keccak256("Upgraded(address)")
bytes32 constant UPGRADED_EVENT_SIG = 0xbc7cd75a20ee27fd9adebab32041f755214dbc6bffa90cc0225b39da2e5c2d3b;

/// @notice ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1967 {
    event Upgraded(address indexed implementation);

    function _upgradeToAndCall(address logic, bytes memory data) internal {
        assembly {
            // if (logic.code.length == 0) revert NotAContract();
            if iszero(extcodesize(logic)) {
                mstore(0, 0x09ee12d5) // NotAContract.selector
                revert(28, 4)
            }

            // bytes32 uuid = ERC1822(logic).proxiableUUID();
            // if (uuid != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();
            mstore(0, 0x52d1902d) // proxiableUUID.selector

            let success := call(gas(), logic, 0, 28, 4, 0, 32)

            // even if call is successful to EOA, memory 0 will never match the uuid
            if iszero(and(success, eq(ERC1967_PROXY_STORAGE_SLOT, mload(0)))) {
                mstore(0, 0x03ed501d) // InvalidUUID.selector
                revert(28, 4)
            }

            // emit Upgraded(logic);
            log2(0, 0, UPGRADED_EVENT_SIG, logic)

            let data_size := mload(data)

            // if (data.length != 0)
            //     (bool success, bytes memory returndata) = logic.delegatecall(data);
            if data_size {
                success := delegatecall(gas(), logic, add(data, 0x20), data_size, 0, 0)

                // if call failed, revert with reason
                if iszero(success) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            // s().implementation = logic;
            sstore(ERC1967_PROXY_STORAGE_SLOT, logic)
        }
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

            let success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success {
                return(0, returndatasize())
            }

            revert(0, returndatasize())
        }
    }
}

/// @notice ERC1822
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract ERC1822 {
    function proxiableUUID() external view virtual returns (bytes32);
}
