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

    function getArg(uint256 argOffset, uint256 argLen) public pure returns (uint256) {
        return LibERC1967ProxyWithImmutableArgs.getArg(argOffset, argLen);
    }

    function getArgAddress(uint256 argOffset) public pure returns (address) {
        return LibERC1967ProxyWithImmutableArgs.getArgAddress(argOffset);
    }

    function getArgBytes32(uint256 argOffset) public pure returns (bytes32) {
        return LibERC1967ProxyWithImmutableArgs.getArgBytes32(argOffset);
    }

    function getArgUint256(uint256 argOffset) public pure returns (uint256) {
        return LibERC1967ProxyWithImmutableArgs.getArgUint256(argOffset);
    }

    function getArgUint128(uint256 argOffset) public pure returns (uint128) {
        return LibERC1967ProxyWithImmutableArgs.getArgUint128(argOffset);
    }

    function getArgUint64(uint256 argOffset) public pure returns (uint64) {
        return LibERC1967ProxyWithImmutableArgs.getArgUint64(argOffset);
    }

    function getArgUint40(uint256 argOffset) public pure returns (uint40) {
        return LibERC1967ProxyWithImmutableArgs.getArgUint40(argOffset);
    }

    function getArgUint8(uint256 argOffset) public pure returns (uint8) {
        return LibERC1967ProxyWithImmutableArgs.getArgUint8(argOffset);
    }
}
