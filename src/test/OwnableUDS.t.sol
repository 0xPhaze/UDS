// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "../proxy/ERC1967Proxy.sol";
import {UUPSUpgradeV} from "../proxy/UUPSUpgradeV.sol";

import "../OwnableUDS.sol";

contract Logic is UUPSUpgradeV, InitializableUDS, OwnableUDS {
    constructor(uint256 version) UUPSUpgradeV(version) {}

    function init() public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}

contract TestOwnableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    Logic proxy;
    Logic proxyUninitialized;

    Logic logicV1;
    Logic logicV2;

    function setUp() public {
        logicV1 = new Logic(1);
        logicV2 = new Logic(2);

        proxy = Logic(address(new ERC1967Proxy(address(logicV1), abi.encodePacked(Logic.init.selector))));
        proxyUninitialized = Logic(address(new ERC1967Proxy(address(logicV1), "")));
    }

    /* ------------- owner() ------------- */

    function test_owner() public {
        assertEq(proxy.owner(), tester);
        // assertEq(proxyUninitialized.owner(), address(0));
    }

    /* ------------- transferOwnership() ------------- */

    function test_transferOwnership() public {
        Logic(proxy).transferOwnership(alice);

        assertEq(proxy.owner(), alice);
    }

    /* ------------- upgradeTo() ------------- */

    function test_upgradeTo() public {
        Logic(proxy).upgradeTo(address(logicV2));

        assertEq(proxy.owner(), tester);
    }

    function test_upgradeTo_fail_CallerNotOwner() public {
        vm.prank(alice);
        vm.expectRevert(CallerNotOwner.selector);
        Logic(proxy).upgradeTo(address(logicV2));
    }

    function test_upgradeTo_fail_CallerNotOwner2() public {
        Logic(proxy).transferOwnership(alice);

        vm.expectRevert(CallerNotOwner.selector);
        Logic(proxy).upgradeTo(address(logicV2));
    }
}
