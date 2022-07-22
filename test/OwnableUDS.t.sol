// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "/auth/OwnableUDS.sol";

contract MockOwnable is MockUUPSUpgrade, OwnableUDS {
    function init() public {
        __Ownable_init();
    }

    function ownerRestricted() public onlyOwner {}
}

contract TestOwnableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    MockOwnable proxy;
    MockOwnable logic;

    function setUp() public {
        logic = new MockOwnable();

        bytes memory initCalldata = abi.encodePacked(MockOwnable.init.selector);

        proxy = MockOwnable(address(new ERC1967Proxy(address(logic), initCalldata)));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        proxy.scrambleStorage(0, 100);

        assertEq(proxy.owner(), tester);

        assertEq(DIAMOND_STORAGE_OWNABLE, keccak256("diamond.storage.ownable"));
    }

    /* ------------- ownerRestricted() ------------- */

    function test_ownerRestricted() public {
        proxy.ownerRestricted();

        // test upgrade to new version
        proxy.upgradeToAndCall(address(new MockOwnable()), "");
        // make sure owner stays the same
        assertEq(proxy.owner(), tester);

        proxy.ownerRestricted();
    }

    function test_ownerRestricted_fail_CallerNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(CallerNotOwner.selector);

        proxy.ownerRestricted();
    }

    function test_ownerRestricted_fail_CallerNotOwner_uninitialized() public {
        proxy = MockOwnable(address(new ERC1967Proxy(address(logic), "")));

        vm.expectRevert(CallerNotOwner.selector);

        proxy.ownerRestricted();

        assertEq(proxy.owner(), address(0));
    }

    /* ------------- transferOwnership() ------------- */

    function test_transferOwnership() public {
        proxy.transferOwnership(alice);

        assertEq(proxy.owner(), alice);

        vm.prank(alice);

        proxy.ownerRestricted();
    }

    function test_transferOwnership_fail_CallerNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(CallerNotOwner.selector);

        proxy.transferOwnership(alice);
    }
}
