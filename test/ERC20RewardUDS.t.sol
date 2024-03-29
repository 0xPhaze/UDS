// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, stdError} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockERC20RewardUDS} from "./mocks/MockERC20RewardUDS.sol";
import {TestERC20UDS, MockERC20UDS} from "./solmate/ERC20UDS.t.sol";

import "UDS/tokens/extensions/ERC20RewardUDS.sol";

contract TestERC20RewardUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address self = address(this);

    address logic;
    MockERC20RewardUDS token;

    function setUp() public {
        logic = address(new MockERC20RewardUDS(1e18, block.timestamp + 1000 days));

        bytes memory initCalldata = abi.encodeWithSelector(MockERC20RewardUDS.init.selector, "Token", "TKN", 18);
        token = MockERC20RewardUDS(address(new ERC1967Proxy(logic, initCalldata)));

        token.scrambleStorage(0, 100);
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
        assertEq(token.rewardDailyRate(), 1e18);
        assertEq(token.rewardEndDate(), block.timestamp + 1000 days);

        ERC20RewardDS storage diamondStorage = s();

        bytes32 slot;

        assembly {
            slot := diamondStorage.slot
        }

        assertEq(slot, keccak256("diamond.storage.erc20.reward"));
        assertEq(DIAMOND_STORAGE_ERC20_REWARD, keccak256("diamond.storage.erc20.reward"));
    }

    /* ------------- increaseMultiplier() ------------- */

    function test_increaseMultiplier(uint216 amountIn) public {
        token.increaseMultiplier(alice, amountIn);
        assertEq(token.getMultiplier(alice), amountIn);
    }

    /* ------------- decreaseMultiplier() ------------- */

    function test_decreaseMultiplier(uint216 amountIn, uint216 amountOut) public {
        test_increaseMultiplier(amountIn);

        if (amountIn >= amountOut) {
            token.decreaseMultiplier(alice, amountOut);

            assertEq(token.getMultiplier(alice), amountIn - amountOut);
        } else {
            vm.expectRevert(stdError.arithmeticError);

            token.decreaseMultiplier(alice, amountOut);
        }
    }

    function test_increaseDecreaseMultiplier() public {
        token.increaseMultiplier(alice, 100_000e18);
        assertEq(token.getMultiplier(alice), 100_000e18);

        // increase twice
        token.increaseMultiplier(alice, 50_000e18);
        assertEq(token.getMultiplier(alice), 150_000e18);

        token.decreaseMultiplier(alice, 150_000e18);
        assertEq(token.getMultiplier(alice), 0);
    }

    /* ------------- setMultiplier() ------------- */

    function test_setMultiplier(uint216 amountIn, uint216 amountSet) public {
        test_increaseMultiplier(amountIn);

        token.setMultiplier(alice, amountSet);
        assertEq(token.getMultiplier(alice), amountSet);
    }

    /* ------------- pendingReward() ------------- */

    function test_pendingReward() public {
        token.increaseMultiplier(alice, 1_000);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.pendingReward(alice), 0);
        assertEq(token.getMultiplier(alice), 1_000);

        skip(100 days);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.pendingReward(alice), 100_000e18);

        // increasing claims for the user
        token.increaseMultiplier(alice, 1_000);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.pendingReward(alice), 0);
        assertEq(token.getMultiplier(alice), 2_000);

        skip(200 days);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.pendingReward(alice), 400_000e18);

        token.decreaseMultiplier(alice, 2_000);

        assertEq(token.balanceOf(alice), 500_000e18);
        assertEq(token.pendingReward(alice), 0);
        assertEq(token.getMultiplier(alice), 0);

        skip(300 days);
    }

    /* ------------- claimReward() ------------- */

    function test_claimReward() public {
        test_pendingReward();
        token.burn(alice, 500_000e18);

        token.increaseMultiplier(alice, 1_000);

        vm.prank(alice);
        token.claimReward();

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.pendingReward(alice), 0);
        assertEq(token.getMultiplier(alice), 1_000);

        skip(100 days);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.pendingReward(alice), 100_000e18);

        vm.prank(alice);
        token.claimReward();

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.pendingReward(alice), 0);

        skip(100 days);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.pendingReward(alice), 100_000e18);

        vm.prank(alice);
        token.claimReward();

        // claiming twice doesn't change
        vm.prank(alice);
        token.claimReward();

        assertEq(token.balanceOf(alice), 200_000e18);
        assertEq(token.pendingReward(alice), 0);
    }

    /* ------------- endDate() ------------- */

    function test_endDate() public {
        token.increaseMultiplier(alice, 1_000);

        skip(100 days);

        assertEq(token.balanceOf(alice), 0);
        assertEq(token.pendingReward(alice), 100_000e18);

        vm.prank(alice);
        token.claimReward();

        // skip to end date
        skip(900 days);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.pendingReward(alice), 900_000e18);

        // waiting any longer doesn't give more due to rewardEndDate
        skip(900 days);

        assertEq(token.balanceOf(alice), 100_000e18);
        assertEq(token.pendingReward(alice), 900_000e18);

        // claim all balance past end date
        vm.prank(alice);
        token.claimReward();

        skip(100 days);

        assertEq(token.balanceOf(alice), 1_000_000e18);
        assertEq(token.pendingReward(alice), 0);
    }
}

// all solmate ERC20 tests should pass
contract TestERC20RewardUDSTestERC20UDS is TestERC20UDS {
    function setUp() public override {
        logic = address(new MockERC20RewardUDS(1e18, block.timestamp + 1000 days));

        bytes memory initCalldata = abi.encodeWithSelector(MockERC20RewardUDS.init.selector, "Token", "TKN", 18);
        token = MockERC20UDS(address(new ERC1967Proxy(logic, initCalldata)));
    }
}
