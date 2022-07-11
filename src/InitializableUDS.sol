// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1822, s as erc1967DS} from "./proxy/ERC1967Proxy.sol";

// ------------- errors

error ProxyCallRequired();
error AlreadyInitialized();

/// @notice Initializable adapted for usage with versioned ERC1967
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract InitializableUDS is ERC1822 {
    address private immutable __implementation = address(this);

    /* ------------- modifier ------------- */

    modifier initializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (erc1967DS().implementation == __implementation) revert AlreadyInitialized();

        _;
    }
}
