// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, stdError} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockERC20BurnableUDS} from "./mocks/MockERC20BurnableUDS.sol";
import {TestERC20, MockERC20UDS} from "./solmate/ERC20UDS.t.sol";

import "UDS/tokens/extensions/ERC20BurnableUDS.sol";

contract TestERC20BurnableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    address logic;
    MockERC20BurnableUDS token;

    uint256 rate = 1e18;

    function setUp() public {
        logic = address(new MockERC20BurnableUDS());

        bytes memory initCalldata = abi.encodeWithSelector(MockERC20BurnableUDS.init.selector, "Token", "TKN", 18);
        token = MockERC20BurnableUDS(address(new ERC1967Proxy(logic, initCalldata)));

        token.scrambleStorage(0, 100);
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
    }

    /* ------------- burn() ------------- */

    function test_burn() public {
        token.mint(alice, 100e18);

        vm.prank(alice);

        token.burn(alice, 20e18);

        assertEq(token.balanceOf(alice), 80e18);
    }

    function test_burn_revert_Underflow() public {
        token.mint(alice, 100e18);

        vm.prank(alice);
        vm.expectRevert(stdError.arithmeticError);

        token.burn(alice, 5000e18);
    }

    function test_burn(
        address user,
        uint256 mintAmount,
        uint256 burnAmount
    ) public {
        token.mint(user, mintAmount);

        if (burnAmount > mintAmount) {
            vm.prank(user);
            vm.expectRevert(stdError.arithmeticError);

            token.burn(user, burnAmount);
        } else {
            vm.prank(user);

            token.burn(user, burnAmount);

            assertEq(token.balanceOf(user), mintAmount - burnAmount);
        }
    }

    /* ------------- burnFrom() ------------- */

    function test_burnFrom() public {
        token.mint(alice, 100e18);

        vm.prank(alice);
        token.approve(tester, 200e18);

        token.burnFrom(alice, 80e18);

        assertEq(token.balanceOf(alice), 20e18);
        assertEq(token.allowance(alice, tester), 120e18);
    }

    function test_burnFrom_revert_Underflow() public {
        token.mint(alice, 100e18);

        vm.prank(alice);
        token.approve(tester, 20e18);

        vm.expectRevert(stdError.arithmeticError);
        token.burnFrom(alice, 80e18);
    }

    function test_burnFrom(
        address user,
        uint256 mintAmount,
        uint256 burnAmount,
        uint256 allowance
    ) public {
        vm.assume(user != tester);

        token.mint(user, mintAmount);

        vm.prank(user);
        token.approve(tester, allowance);

        if (burnAmount > allowance) {
            vm.expectRevert(stdError.arithmeticError);

            token.burnFrom(user, burnAmount);
        } else if (burnAmount > mintAmount) {
            vm.expectRevert(stdError.arithmeticError);

            token.burnFrom(user, burnAmount);
        } else {
            token.burnFrom(user, burnAmount);

            assertEq(token.balanceOf(user), mintAmount - burnAmount);

            if (allowance != type(uint256).max) assertEq(token.allowance(user, tester), allowance - burnAmount);
        }
    }
}

// all solmate ERC20 tests should pass
contract TestERC20UDS is TestERC20 {
    function setUp() public override {
        logic = address(new MockERC20BurnableUDS());

        bytes memory initCalldata = abi.encodeWithSelector(MockERC20BurnableUDS.init.selector, "Token", "TKN", 18);
        token = MockERC20UDS(address(new ERC1967Proxy(logic, initCalldata)));
    }
}
