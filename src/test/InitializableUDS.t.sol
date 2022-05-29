// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ERC1967Proxy} from "../proxy/ERC1967VersionedUDS.sol";
import {UUPSVersionedUpgrade} from "../proxy/UUPSVersionedUpgrade.sol";

import "../InitializableUDS.sol";

contract Logic is UUPSVersionedUpgrade, InitializableUDS {
    constructor(uint256 version) UUPSVersionedUpgrade(version) {}

    bool public initialized;

    function initializerRestricted() public initializer {
        initialized = true;
    }

    function _authorizeUpgrade() internal override {}
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

        assertFalse(proxy.initialized());
    }

    /* ------------- initializerRestricted() ------------- */

    function test_initializerRestricted() public {
        proxy.upgradeToAndCall(address(logicV2), abi.encodePacked(logicV2.initializerRestricted.selector));

        assertTrue(proxy.initialized());
    }

    function test_initializerRestricted_fail_InvalidUpgradeVersion() public {
        vm.expectRevert(InvalidInitializerVersion.selector);
        proxy.initializerRestricted();

        proxy.upgradeTo(address(logicV2));

        vm.expectRevert(InvalidInitializerVersion.selector);
        proxy.initializerRestricted();
    }

    function test_initializerRestricted_fail_NotProxyCall() public {
        vm.expectRevert(ProxyCallRequired.selector);
        logicV1.initializerRestricted();

        proxy.upgradeTo(address(logicV2));

        vm.expectRevert(ProxyCallRequired.selector);
        logicV1.initializerRestricted();
    }
}
