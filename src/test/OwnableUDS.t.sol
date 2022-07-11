// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "../proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "../OwnableUDS.sol";

contract Logic is MockUUPSUpgrade, InitializableUDS, OwnableUDS {
    constructor(uint256 version) MockUUPSUpgrade(version) {}

    function init() public initializer {
        __Ownable_init();
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}

contract TestOwnableUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    Logic proxy;

    Logic logicV1;
    Logic logicV2;

    function setUp() public {
        logicV1 = new Logic(1);
        logicV2 = new Logic(2);

        bytes memory calldata_ = abi.encodePacked(Logic.init.selector);
        proxy = Logic(address(new ERC1967Proxy(address(logicV1), calldata_)));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        // make sure that s().owner is not
        // located in sequential storage slot
        proxy.scrambleStorage();

        assertEq(proxy.owner(), tester);
    }

    /* ------------- upgradeTo() ------------- */

    function test_upgradeTo() public {
        // test upgrade to new version
        proxy.upgradeTo(address(logicV2));

        // make sure owner stays the same
        assertEq(proxy.owner(), tester);

        // test upgrade to new version
        proxy.upgradeTo(address(logicV1));
    }

    /// don't call init during proxy deployment
    /// this makes the proxy non-upgradeable
    /// because owner is not set
    function test_upgradeTo_fail_CallerNotOwner() public {
        proxy = Logic(address(new ERC1967Proxy(address(logicV1), "")));
        assertEq(proxy.owner(), address(0));

        vm.expectRevert(CallerNotOwner.selector);
        proxy.upgradeTo(address(logicV2));
    }

    /* ------------- transferOwnership() ------------- */

    function test_transferOwnership() public {
        proxy.transferOwnership(alice);

        assertEq(proxy.owner(), alice);

        // can't upgrade anymore because of owner restriction
        vm.expectRevert(CallerNotOwner.selector);
        proxy.upgradeTo(address(logicV2));

        // alice is able to upgrade
        vm.prank(alice);
        proxy.upgradeTo(address(logicV2));
    }
}
