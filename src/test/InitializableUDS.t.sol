// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "../proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "../InitializableUDS.sol";

contract Logic is MockUUPSUpgrade, InitializableUDS {
    uint256 public initializedCount;

    constructor(uint256 version) MockUUPSUpgrade(version) {}

    function initializerRestricted() public initializer {
        ++initializedCount;
    }
}

contract TestInitializableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    Logic proxy;
    Logic logicV1;
    Logic logicV2;

    function setUp() public {
        logicV1 = new Logic(1);
        logicV2 = new Logic(2);

        proxy = Logic(address(new ERC1967Proxy(address(logicV1), "")));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(proxy.version(), 1);
        assertEq(proxy.initializedCount(), 0);
        assertEq(proxy.implementation(), address(logicV1));

        assertEq(logicV1.version(), 1);
        assertEq(logicV1.initializedCount(), 0);

        assertEq(logicV2.version(), 2);
        assertEq(logicV2.initializedCount(), 0);
    }

    /* ------------- initializerRestricted() ------------- */

    /// make sure initializerRestricted function can't be called
    function test_initializerRestricted_fail() public {
        vm.expectRevert(AlreadyInitialized.selector);
        proxy.initializerRestricted();

        vm.expectRevert(ProxyCallRequired.selector);
        logicV1.initializerRestricted();

        vm.expectRevert(ProxyCallRequired.selector);
        logicV2.initializerRestricted();

        proxy.upgradeToAndCall(address(logicV2), "");

        vm.expectRevert(AlreadyInitialized.selector);
        proxy.initializerRestricted();

        vm.expectRevert(ProxyCallRequired.selector);
        logicV1.initializerRestricted();

        vm.expectRevert(ProxyCallRequired.selector);
        logicV2.initializerRestricted();
    }

    /// call initializerRestricted during upgrade
    function test_upgradeToAndCallInitializerRestricted() public {
        proxy.upgradeToAndCall(address(logicV2), abi.encodePacked(Logic.initializerRestricted.selector));

        assertEq(proxy.version(), 2);
        assertEq(proxy.implementation(), address(logicV2));
        assertEq(proxy.initializedCount(), 1);

        // switch back to v1
        proxy.upgradeToAndCall(address(logicV1), abi.encodePacked(Logic.initializerRestricted.selector));

        assertEq(proxy.version(), 1);
        assertEq(proxy.implementation(), address(logicV1));
        assertEq(proxy.initializedCount(), 2);
    }
}
