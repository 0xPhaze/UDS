// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "/auth/AccessControlUDS.sol";

contract MockAccessControl is MockUUPSUpgrade, AccessControlUDS {
    function init() public initializer {
        __AccessControl_init();
    }

    function roleRestricted(bytes32 role) public onlyRole(role) {}
}

contract TestAccessControlUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    MockAccessControl proxy;
    MockAccessControl logic;

    function setUp() public {
        logic = new MockAccessControl();

        bytes memory initCalldata = abi.encodePacked(MockAccessControl.init.selector);

        proxy = MockAccessControl(address(new ERC1967Proxy(address(logic), initCalldata)));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        proxy.scrambleStorage(0, 100);

        proxy.hasRole(0x00, tester);

        assertEq(DIAMOND_STORAGE_ACCESS_CONTROL, keccak256("diamond.storage.access.control"));
    }

    /* ------------- hasRole() ------------- */

    function test_hasRole(bytes32 role, address user) public {
        vm.assume(user != tester);

        assertFalse(proxy.hasRole(role, user));

        vm.expectRevert(NotAuthorized.selector);

        proxy.roleRestricted(role);
    }

    /* ------------- grantRole() ------------- */

    function test_grantRole(bytes32 role, address user) public {
        proxy.grantRole(role, user);

        assertTrue(proxy.hasRole(role, user));

        vm.prank(user);

        proxy.roleRestricted(role);
    }

    function test_grantRole_fail_NotAuthorized(
        address caller,
        bytes32 role,
        address user
    ) public {
        vm.assume(user != tester);

        vm.prank(caller);
        vm.expectRevert(NotAuthorized.selector);

        proxy.grantRole(role, user);
    }

    /* ------------- renounceRole() ------------- */

    function test_renounceRole(bytes32 role, address user) public {
        proxy.grantRole(role, user);

        vm.prank(user);

        proxy.renounceRole(role);

        assertFalse(proxy.hasRole(role, user));

        vm.expectRevert(NotAuthorized.selector);

        proxy.roleRestricted(role);
    }

    /* ------------- setRoleAdmin() ------------- */

    function test_setRoleAdmin(bytes32 role, bytes32 adminRole) public {
        proxy.setRoleAdmin(role, adminRole);

        assertEq(proxy.getRoleAdmin(role), adminRole);
    }

    function test_setRoleAdmin2(
        bytes32 role,
        bytes32 adminRole1,
        bytes32 adminRole2,
        address user
    ) public {
        proxy.grantRole(adminRole1, user);

        proxy.setRoleAdmin(role, adminRole1);

        assertTrue(proxy.hasRole(adminRole1, user));

        vm.prank(user);

        proxy.setRoleAdmin(role, adminRole2);

        assertEq(proxy.getRoleAdmin(role), adminRole2);
    }

    function test_setRoleAdmin_fail_NotAuthorized(
        address user,
        bytes32 role,
        bytes32 adminRole
    ) public {
        vm.assume(user != tester);

        vm.prank(user);
        vm.expectRevert(NotAuthorized.selector);

        proxy.setRoleAdmin(role, adminRole);
    }

    function test_setRoleAdmin_fail_NotAuthorized2(
        bytes32 role,
        bytes32 adminRole1,
        bytes32 adminRole2,
        address user
    ) public {
        proxy.grantRole(adminRole1, user);

        proxy.setRoleAdmin(role, adminRole1);

        vm.expectRevert(NotAuthorized.selector);

        proxy.setRoleAdmin(role, adminRole2);
    }
}
