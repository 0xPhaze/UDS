// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "UDS/auth/Initializable.sol";

contract MockInitializable is MockUUPSUpgrade, Initializable {
    uint256 public initializedCount;
    uint256 public immutable version;

    constructor(uint256 version_) {
        version = version_;
    }

    function initializerRestricted() public initializer {
        ++initializedCount;
    }

    function reinitializerRestricted() public reinitializer {
        ++initializedCount;
    }
}

contract TestInitializable is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    address logicV1;
    address logicV2;
    MockInitializable proxy;

    function setUp() public {
        logicV1 = address(new MockInitializable(1));
        logicV2 = address(new MockInitializable(2));

        proxy = MockInitializable(address(new ERC1967Proxy(logicV1, "")));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(proxy.version(), 1);
        assertEq(proxy.initializedCount(), 0);
        assertEq(proxy.implementation(), logicV1);
    }

    /* ------------- initializerRestricted() ------------- */

    /// call initializerRestricted during deployment
    function test_initializerRestricted_deployAndCall() public {
        bytes memory initCalldata = abi.encodePacked(MockInitializable.initializerRestricted.selector);

        proxy = MockInitializable(address(new ERC1967Proxy(logicV2, initCalldata)));
    }

    /// call initializerRestricted during upgrade
    function test_initializerRestricted_upgradeToAndCall_fail_AlreadyInitialized() public {
        bytes memory initCalldata = abi.encodePacked(MockInitializable.initializerRestricted.selector);

        vm.expectRevert(AlreadyInitialized.selector);

        proxy.upgradeToAndCall(logicV2, initCalldata);
    }

    /// call initializerRestricted directly on implementation contract
    function test_initializerRestricted_fail_AlreadyInitialized() public {
        vm.expectRevert(AlreadyInitialized.selector);
        MockInitializable(logicV1).initializerRestricted();

        vm.expectRevert(AlreadyInitialized.selector);
        MockInitializable(logicV2).initializerRestricted();
    }

    /* ------------- reinitializerRestricted() ------------- */

    /// call reinitializerRestricted during deployment
    function test_reinitializerRestricted_deployAndCall() public {
        bytes memory initCalldata = abi.encodePacked(MockInitializable.reinitializerRestricted.selector);

        proxy = MockInitializable(address(new ERC1967Proxy(logicV2, initCalldata)));

        assertEq(proxy.initializedCount(), 1);
    }

    /// call reinitializerRestricted during upgrade
    function test_reinitializerRestricted_upgradeToAndCall() public {
        bytes memory initCalldata = abi.encodePacked(MockInitializable.reinitializerRestricted.selector);

        proxy.upgradeToAndCall(logicV2, initCalldata);

        assertEq(proxy.initializedCount(), 1);

        // test for another upgrade
        proxy.upgradeToAndCall(logicV1, initCalldata);

        assertEq(proxy.initializedCount(), 2);
    }

    /// call reinitializerRestricted outside of upgrade
    function test_reinitializerRestricted_fail_AlreadyInitialized() public {
        vm.expectRevert(AlreadyInitialized.selector);
        proxy.reinitializerRestricted();

        // test after another upgrade
        proxy.upgradeToAndCall(logicV2, "");

        vm.expectRevert(AlreadyInitialized.selector);
        proxy.reinitializerRestricted();
    }

    /// call reinitializerRestricted directly on implementation contract
    function test_reinitializerRestricted_fail_ProxyCallRequired() public {
        vm.expectRevert(ProxyCallRequired.selector);
        MockInitializable(logicV1).reinitializerRestricted();

        vm.expectRevert(ProxyCallRequired.selector);
        MockInitializable(logicV2).reinitializerRestricted();
    }
}
