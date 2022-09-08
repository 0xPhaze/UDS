// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "UDS/auth/PausableUDS.sol";

contract MockPausable is MockUUPSUpgrade, PausableUDS {
    function isPaused() public view returns (bool) {
        return s().paused == 2;
    }

    function unpause() public {
        _unpause();
    }

    function pause() public {
        _pause();
    }

    function onlyUnpaused() public notPaused {}
}

contract TestPausableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    address logic;
    MockPausable proxy;

    function setUp() public {
        logic = address(new MockPausable());

        proxy = MockPausable(address(new ERC1967Proxy(logic, "")));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        proxy.scrambleStorage(0, 100);

        assertEq(proxy.isPaused(), false);

        assertEq(DIAMOND_STORAGE_PAUSABLE, keccak256("diamond.storage.pausable"));
    }

    /* ------------- onlyUnpaused() ------------- */

    /// call onlyUnpaused
    function test_onlyUnpaused() public {
        proxy.onlyUnpaused();

        // check again when paused state == 1
        proxy.pause();
        proxy.unpause();

        proxy.onlyUnpaused();
    }

    /// call onlyUnpaused when contract is paused
    function test_onlyUnpaused_revert_Paused() public {
        proxy.pause();

        vm.expectRevert(Paused.selector);

        proxy.onlyUnpaused();
    }

    /* ------------- pause() ------------- */

    /// pause contract
    function test_pause() public {
        proxy.pause();

        assertEq(proxy.isPaused(), true);
    }

    /// pause contract when already paused
    function test_pause_revert_AlreadyPaused() public {
        proxy.pause();

        vm.expectRevert(AlreadyPaused.selector);

        proxy.pause();
    }

    /* ------------- unpause() ------------- */

    /// unpause contract
    function test_unpause() public {
        proxy.pause();

        proxy.unpause();

        assertEq(proxy.isPaused(), false);
    }

    /// unpause contract
    function test_unpause_revert_AlreadyPaused() public {
        vm.expectRevert(AlreadyUnpaused.selector);

        proxy.unpause();

        // check again when paused state == 1
        proxy.pause();
        proxy.unpause();

        vm.expectRevert(AlreadyUnpaused.selector);

        proxy.unpause();
    }
}
