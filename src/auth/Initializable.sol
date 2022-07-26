// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1822, s as erc1967DS} from "../proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @title Initializable
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @dev functions using the `initializer` modifier are only callable through a proxy
/// @dev and only before a proxy upgrade migration has completed
/// @dev (only when `upgradeToAndCall`'s `initCalldata` is being executed)
/// @dev allows re-initialization during upgrades
abstract contract Initializable {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967DS().implementation == __implementation) revert AlreadyInitialized();
        _;
    }
}
