// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967, DIAMOND_STORAGE_ERC1967_UPGRADE, ERC1822} from "./ERC1967Proxy.sol";

// ------------- errors

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/// @notice Minimal UUPSUpgrade
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract UUPSUpgrade is ERC1967, ERC1822 {
    address private immutable __implementation = address(this);

    /* ------------- external ------------- */

    function upgradeToAndCall(address logic, bytes calldata data) external {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, data);
    }

    /* ------------- view ------------- */

    function proxiableUUID() external view override notDelegated returns (bytes32) {
        return DIAMOND_STORAGE_ERC1967_UPGRADE;
    }

    /* ------------- virtual ------------- */

    function _authorizeUpgrade() internal virtual;

    /* ------------- modifier ------------- */

    modifier onlyProxy() {
        if (address(this) == __implementation) revert OnlyProxyCallAllowed();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();
        _;
    }
}