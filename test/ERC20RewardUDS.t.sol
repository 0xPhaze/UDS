// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, stdError} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";
import {MockERC20RewardUDS} from "./mocks/MockERC20RewardUDS.sol";
import {ERC20Test, MockERC20UDS} from "./solmate/ERC20UDS.t.sol";

import "UDS/tokens/ERC20RewardUDS.sol";

contract TestERC20RewardUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    MockERC20RewardUDS token;
    MockERC20RewardUDS logic;

    uint256 rate = 1e18;

    function setUp() public {
        logic = new MockERC20RewardUDS(rate, block.timestamp + 1000 days);

        bytes memory initCalldata = abi.encodeWithSelector(MockERC20RewardUDS.init.selector, "Token", "TKN", 18);
        token = MockERC20RewardUDS(address(new ERC1967Proxy(address(logic), initCalldata)));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        // make sure that storage data is not
        // located in sequential storage slot
        token.scrambleStorage(0, 100);

        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);

        assertEq(DIAMOND_STORAGE_ERC20_REWARD, keccak256("diamond.storage.erc20.reward"));
    }

    /* ------------- getMultiplier() ------------- */

    function test_getMultiplier() public {
        token.increaseMultiplier(alice, 0);

        assertEq(token.getMultiplier(alice), 0);

        token.increaseMultiplier(alice, 100_000e18);

        assertEq(token.getMultiplier(alice), 100_000e18);

        // increase twice
        token.increaseMultiplier(alice, 100_000e18);

        assertEq(token.getMultiplier(alice), 200_000e18);

        token.decreaseMultiplier(alice, 100_000e18);

        assertEq(token.getMultiplier(alice), 100_000e18);

        // underflow
        vm.expectRevert(stdError.arithmeticError);
        token.decreaseMultiplier(alice, 500_000e18);

        token.decreaseMultiplier(alice, 100_000e18);

        assertEq(token.getMultiplier(alice), 0);
    }

    /* ------------- increaseMultiplier() ------------- */

    function test_increaseRewardMultiplier() public {
        token.increaseMultiplier(alice, 1_000);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.virtualBalanceOf(alice), 0);

        skip(100 days);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.virtualBalanceOf(alice), 100_000e18);

        // increasing claims for the user
        token.increaseMultiplier(alice, 1_000);

        skip(200 days);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.virtualBalanceOf(alice), 400_000e18);

        token.decreaseMultiplier(alice, 2_000);
    }

    /* ------------- claimVirtualBalance() ------------- */

    function test_claimVirtualBalance() public {
        token.increaseMultiplier(alice, 1_000);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.virtualBalanceOf(alice), 0);

        token.claimVirtualBalance();

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.virtualBalanceOf(alice), 0);

        skip(100 days);

        // alice should have 100_000 tokens at her disposal
        // virtual balance is counted in balanceOf
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.virtualBalanceOf(alice), 100_000e18);

        // claim virtual balance to balance
        vm.prank(alice);
        token.claimVirtualBalance();

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.virtualBalanceOf(alice), 0);

        skip(100 days);

        // another 100 days
        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.virtualBalanceOf(alice), 100_000e18);

        // claim again
        vm.prank(alice);
        token.claimVirtualBalance();

        // claiming twice doesn't change
        vm.prank(alice);
        token.claimVirtualBalance();

        assertEq(token.balanceOf(alice), 200_000e18);
        assertEq(token.virtualBalanceOf(alice), 0);
    }

    /* ------------- endDate() ------------- */

    function test_endDate() public {
        token.increaseMultiplier(alice, 1_000);

        skip(100 days);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.virtualBalanceOf(alice), 100_000e18);

        vm.prank(alice);
        token.claimVirtualBalance();

        // skip to end date
        skip(900 days);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.virtualBalanceOf(alice), 900_000e18);

        // waiting any longer doesn't give more due to rewardEndDate
        skip(900 days);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.virtualBalanceOf(alice), 900_000e18);

        // claim all balance past end date
        vm.prank(alice);
        token.claimVirtualBalance();

        skip(100 days);

        assertEq(token.balanceOf(alice), 1_000_000e18);
        assertEq(token.virtualBalanceOf(alice), 0);
    }
}

// all solmate ERC20 tests should pass
contract TestERC20UDS is ERC20Test {
    function setUp() public override {
        logic = MockERC20UDS(address(new MockERC20RewardUDS(1e18, block.timestamp + 1000 days)));

        bytes memory initCalldata = abi.encodeWithSelector(MockERC20RewardUDS.init.selector, "Token", "TKN", 18);
        token = MockERC20UDS(address(new ERC1967Proxy(address(logic), initCalldata)));
    }
}
