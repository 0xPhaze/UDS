// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "UDS/auth/ReentrancyGuardUDS.sol";

contract MockReentrancyGuard is MockUUPSUpgrade, ReentrancyGuardUDS {
    uint256 private numEntries = 0;

    function init() public nonReentrant {
        // not necessary to init
    }

    function unguardedReentrancy() public {
        if (++numEntries == 1) this.unguardedReentrancy();
    }

    function guardedReentrancy() public nonReentrant {
        if (++numEntries == 1) this.guardedReentrancy();
    }
}

contract TestReentrancyGuardUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address self = address(this);

    address logic;
    MockReentrancyGuard proxy;

    function setUp() public {
        logic = address(new MockReentrancyGuard());

        bytes memory initCalldata = abi.encodePacked(MockReentrancyGuard.init.selector);

        proxy = MockReentrancyGuard(address(new ERC1967Proxy(logic, initCalldata)));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        proxy.scrambleStorage(0, 100);

        ReentrancyGuardDS storage diamondStorage = s();

        bytes32 slot;

        assembly {
            slot := diamondStorage.slot
        }

        assertEq(slot, keccak256("diamond.storage.reentrancy.guard"));
        assertEq(DIAMOND_STORAGE_REENTRANCY_GUARD, keccak256("diamond.storage.reentrancy.guard"));
    }

    /* ------------- guardedReentrancy() ------------- */

    /// call guardedReentrancy
    function test_guardedReentrancy_revert_ReentrancyNotPermitted() public {
        vm.expectRevert(ReentrancyNotPermitted.selector);

        proxy.guardedReentrancy();
    }

    /* ------------- unguardedReentrancy() ------------- */

    // call unguardedReentrancy
    function test_guardedReentrancy() public {
        proxy.unguardedReentrancy();
    }
}
