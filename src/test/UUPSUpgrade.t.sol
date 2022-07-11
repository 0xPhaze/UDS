// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "../proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

contract LogicV1 is MockUUPSUpgrade(1) {
    uint256 public data = 0x1337;

    function fn() public pure returns (uint256) {
        return 1337;
    }

    function setData(uint256 newData) public {
        data = newData;
    }
}

contract LogicV2 is MockUUPSUpgrade(2) {
    address public data = address(0x42);

    function fn() public pure returns (uint256) {
        return 6969;
    }

    function fn2() public pure returns (uint256) {
        return 3141;
    }
}

contract TestUUPSUpgrade is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    address proxy;
    LogicV1 logicV1;
    LogicV2 logicV2;

    function setUp() public virtual {
        logicV1 = new LogicV1();
        logicV2 = new LogicV2();

        proxy = address(new ERC1967Proxy(address(logicV1), ""));
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(logicV1.version(), 1);
        assertEq(logicV2.version(), 2);
        assertEq(LogicV1(proxy).version(), 1);

        assertEq(logicV1.fn(), 1337);
        assertEq(logicV2.fn(), 6969);
        assertEq(logicV2.fn2(), 3141);
        assertEq(LogicV1(proxy).fn(), 1337);

        assertEq(logicV1.data(), 0x1337);
        assertEq(logicV2.data(), address(0x42));
        assertEq(LogicV1(proxy).data(), 0);

        // make sure that s().implementation is not
        // located in sequential storage slot
        MockUUPSUpgrade(proxy).scrambleStorage();
        assertEq(MockUUPSUpgrade(proxy).implementation(), address(logicV1));
    }

    /* ------------- upgradeTo() ------------- */

    /// check implementation's public funcions
    function test_upgradeTo() public {
        // proxy can call v1's setData
        LogicV1(proxy).setData(0x3333);

        assertEq(LogicV1(proxy).data(), 0x3333); // proxy's data now has changed
        assertEq(logicV1.data(), 0x1337); // implementation's data remains unchanged

        // upgrade to v2
        LogicV1(proxy).upgradeTo(address(logicV2));

        // only available under v1 logic
        vm.expectRevert();
        LogicV1(proxy).setData(0x456);

        // test v2 functions
        assertEq(LogicV2(proxy).fn(), 6969);
        assertEq(LogicV2(proxy).fn2(), 3141);

        // make sure data remains unchanged (though returned as address now)
        assertEq(LogicV2(proxy).data(), address(0x3333));

        // upgrade back to v1
        LogicV2(proxy).upgradeTo(address(logicV1));

        // only available under v2 logic
        vm.expectRevert();
        LogicV2(proxy).fn2();

        // v1's setData works again
        LogicV1(proxy).setData(0x6666);

        assertEq(LogicV1(proxy).data(), 0x6666);
    }
}
