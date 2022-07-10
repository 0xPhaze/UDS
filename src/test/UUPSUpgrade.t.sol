// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "../proxy/ERC1967Proxy.sol";
import {UUPSUpgradeV} from "../proxy/UUPSUpgradeV.sol";

error InvalidUpgradeVersion();

contract MockLogicV1 is UUPSUpgradeV(1) {
    address public owner = address(0xb0b);

    function fn() public pure returns (uint256) {
        return 1337;
    }

    function setOwner(address newOwner) public {
        owner = newOwner;
    }

    function _authorizeUpgrade() internal virtual override {}
}

contract MockLogicV2 is UUPSUpgradeV(2) {
    address public owner = address(1);

    function fn2() public pure returns (uint256) {
        return 6969;
    }

    function _authorizeUpgrade() internal virtual override {}
}

contract TestUUPSUpgradeV is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    address proxy;
    MockLogicV1 logicV1;
    MockLogicV2 logicV2;

    function setUp() public {
        logicV1 = new MockLogicV1();
        logicV2 = new MockLogicV2();

        proxy = address(new ERC1967Proxy(address(logicV1), ""));

        assertEq(logicV1.proxiableVersion(), 1);
        assertEq(logicV2.proxiableVersion(), 2);
        assertEq(MockLogicV1(proxy).proxiableVersion(), 1);
    }

    /* ------------- owner() ------------- */

    function test_owner() public {
        assertEq(MockLogicV1(proxy).owner(), address(0));
        assertEq(logicV1.owner(), address(0xb0b));

        MockLogicV1(proxy).setOwner(tester);

        assertEq(MockLogicV1(proxy).owner(), tester);
        assertEq(logicV1.owner(), address(0xb0b));
    }

    function test_owner_fail() public {
        MockLogicV1(proxy).upgradeTo(address(logicV2));

        vm.expectRevert();
        MockLogicV1(proxy).setOwner(tester);
    }

    /* ------------- upgradeTo() ------------- */

    function test_upgradeVersion() public {
        assertEq(MockLogicV1(proxy).proxiableVersion(), 1);
        assertEq(MockLogicV1(proxy).fn(), 1337);

        MockLogicV1(proxy).upgradeTo(address(logicV2));

        assertEq(MockLogicV2(proxy).proxiableVersion(), 2);
        assertEq(MockLogicV2(proxy).fn2(), 6969);
    }

    function test_upgradeVersion_fail_InvalidUpgradeVersion() public {
        vm.expectRevert(InvalidUpgradeVersion.selector);
        MockLogicV1(proxy).upgradeTo(address(logicV1));

        MockLogicV1(proxy).upgradeTo(address(logicV2));

        vm.expectRevert(InvalidUpgradeVersion.selector);
        MockLogicV1(proxy).upgradeTo(address(logicV1));

        vm.expectRevert(InvalidUpgradeVersion.selector);
        MockLogicV1(proxy).upgradeTo(address(logicV2));
    }
}
