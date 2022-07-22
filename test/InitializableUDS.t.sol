// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "/auth/InitializableUDS.sol";

contract MockInitializable is MockUUPSUpgrade, InitializableUDS {
    uint256 public initializedCount;
    uint256 public immutable version;

    constructor(uint256 version_) {
        version = version_;
    }

    function initializerRestricted() public initializer {
        ++initializedCount;
    }
}

contract TestInitializableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    MockInitializable proxy;
    MockInitializable logicV1;
    MockInitializable logicV2;

    function setUp() public {
        logicV1 = new MockInitializable(1);
        logicV2 = new MockInitializable(2);

        proxy = MockInitializable(address(new ERC1967Proxy(address(logicV1), "")));
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

    /// call initializerRestricted during deployment
    function test_deployAndCall_initializerRestricted() public {
        proxy = MockInitializable(
            address(
                new ERC1967Proxy(address(logicV2), abi.encodePacked(MockInitializable.initializerRestricted.selector))
            )
        );

        assertEq(proxy.version(), 2);
        assertEq(proxy.implementation(), address(logicV2));
        assertEq(proxy.initializedCount(), 1);

        // switch back to v1
        proxy.upgradeToAndCall(address(logicV1), abi.encodePacked(MockInitializable.initializerRestricted.selector));

        assertEq(proxy.version(), 1);
        assertEq(proxy.implementation(), address(logicV1));
        assertEq(proxy.initializedCount(), 2);
    }

    /// call initializerRestricted during upgrade
    function test_upgradeToAndCall_initializerRestricted() public {
        proxy.upgradeToAndCall(address(logicV2), abi.encodePacked(MockInitializable.initializerRestricted.selector));

        assertEq(proxy.version(), 2);
        assertEq(proxy.implementation(), address(logicV2));
        assertEq(proxy.initializedCount(), 1);

        // switch back to v1
        proxy.upgradeToAndCall(address(logicV1), abi.encodePacked(MockInitializable.initializerRestricted.selector));

        assertEq(proxy.version(), 1);
        assertEq(proxy.implementation(), address(logicV1));
        assertEq(proxy.initializedCount(), 2);
    }

    /// make sure initializerRestricted function can't be called
    function test_initializerRestricted_fail_AlreadyInitialized() public {
        vm.expectRevert(AlreadyInitialized.selector);
        proxy.initializerRestricted();

        proxy.upgradeToAndCall(address(logicV2), "");

        vm.expectRevert(AlreadyInitialized.selector);
        proxy.initializerRestricted();
    }

    function test_initializerRestricted_fail_ProxyCallRequired() public {
        vm.expectRevert(ProxyCallRequired.selector);
        logicV1.initializerRestricted();

        vm.expectRevert(ProxyCallRequired.selector);
        logicV2.initializerRestricted();
    }
}
