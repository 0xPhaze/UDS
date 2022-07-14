// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibERC1967ProxyWithImmutableArgs} from "../../src/proxy/ERC1967ProxyWithImmutableArgs.sol";
import {MockUUPSUpgrade} from "./MockUUPSUpgrade.sol";

abstract contract MockUUPSUpgradeWithImmutableArgs is MockUUPSUpgrade {
    constructor(uint256 version) MockUUPSUpgrade(version) {}

    function arg1() public pure returns (bytes32) {
        return LibERC1967ProxyWithImmutableArgs.getArgBytes32(0);
    }

    function arg2() public pure returns (bytes32) {
        return LibERC1967ProxyWithImmutableArgs.getArgBytes32(32);
    }

    function arg3() public pure returns (bytes32) {
        return LibERC1967ProxyWithImmutableArgs.getArgBytes32(64);
    }
}
