// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1822Versioned} from "./proxy/ERC1822Versioned.sol";
import {s as erc1967DS} from "./proxy/ERC1967VersionedUDS.sol";

/* ============= Errors ============= */

error NotInitializing();
error ProxyCallRequired();
error InvalidInitializerVersion();

/* ============= InitializableUDS ============= */

abstract contract InitializableUDS is ERC1822Versioned {
    address private immutable __implementation = address(this);

    /* ------------- Modifier ------------- */

    modifier initializer() {
        if (address(this) == __implementation) revert ProxyCallRequired();
        if (proxiableVersion() <= erc1967DS().version) revert InvalidInitializerVersion();

        _;
    }
}
