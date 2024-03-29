// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "UDS/auth/OwnableUDS.sol";

contract MockOwnable is MockUUPSUpgrade, OwnableUDS {
    function init() public {
        __Ownable_init();
    }

    function ownerRestricted() public onlyOwner {}
}

contract TestOwnableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address self = address(this);

    address logic;
    MockOwnable proxy;

    function setUp() public {
        logic = address(new MockOwnable());

        bytes memory initCalldata = abi.encodePacked(MockOwnable.init.selector);

        proxy = MockOwnable(address(new ERC1967Proxy(logic, initCalldata)));

        proxy.scrambleStorage(0, 100);
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(proxy.owner(), self);

        OwnableDS storage diamondStorage = s();

        bytes32 slot;

        assembly {
            slot := diamondStorage.slot
        }

        assertEq(slot, keccak256("diamond.storage.ownable"));
        assertEq(DIAMOND_STORAGE_OWNABLE, keccak256("diamond.storage.ownable"));
    }

    /* ------------- ownerRestricted() ------------- */

    /// call ownerRestricted as owner
    function test_ownerRestricted() public {
        proxy.ownerRestricted();

        // make sure owner stays after an upgrade
        proxy.upgradeToAndCall(address(new MockOwnable()), "");

        assertEq(proxy.owner(), self);

        proxy.ownerRestricted();
    }

    /// call ownerRestricted as non-owner
    function test_ownerRestricted_revert_CallerNotOwner(address caller) public {
        vm.assume(caller != self);

        vm.prank(caller);
        vm.expectRevert(CallerNotOwner.selector);

        proxy.ownerRestricted();
    }

    /// don't call init on deployment, ownable should be 0
    function test_ownerRestricted_revert_CallerNotOwner_uninitialized(address caller) public {
        vm.assume(caller != address(0));

        proxy = MockOwnable(address(new ERC1967Proxy(logic, "")));

        assertEq(proxy.owner(), address(0));

        vm.prank(caller);
        vm.expectRevert(CallerNotOwner.selector);

        proxy.ownerRestricted();
    }

    /* ------------- transferOwnership() ------------- */

    /// transfer ownership and make sure they can call ownerRestricted
    function test_transferOwnership(address newOwner) public {
        proxy.transferOwnership(newOwner);

        assertEq(proxy.owner(), newOwner);

        vm.prank(newOwner);

        proxy.ownerRestricted();
    }

    /// transferOwnership should only be callable by owner
    function test_transferOwnership_revert_CallerNotOwner(address caller) public {
        vm.assume(caller != self);

        vm.prank(caller);
        vm.expectRevert(CallerNotOwner.selector);

        proxy.transferOwnership(caller);
    }
}
