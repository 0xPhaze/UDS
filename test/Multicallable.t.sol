// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "UDS/utils/Multicallable.sol";

contract MockMulticallable is MockUUPSUpgrade, Multicallable {
    uint256 public func1Arg;
    uint256 public func2Arg1;
    bytes public func2Arg2;

    function func1(uint256 data) public {
        func1Arg = data;
    }

    function func2(uint256 arg1, bytes calldata arg2) public {
        require(msg.sender == tx.origin);

        func2Arg1 = arg1;
        func2Arg2 = arg2;
    }
}

contract TestMulticallable is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address self = address(this);

    MockMulticallable proxy;

    function setUp() public {
        address logic = address(new MockMulticallable());

        proxy = MockMulticallable(address(new ERC1967Proxy(logic, "")));
    }

    /* ------------- multicall() ------------- */

    function test_multicall() public {
        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeCall(proxy.func1, (0x1337));
        data[1] = abi.encodeCall(proxy.func2, (0x1234, "hello"));
        data[2] = abi.encodeCall(proxy.func2, (0x3333, "test 123"));

        vm.prank(self, self);
        proxy.multicall(data);

        assertEq(proxy.func1Arg(), 0x1337);
        assertEq(proxy.func2Arg1(), 0x3333);
        assertEq(proxy.func2Arg2(), "test 123");
    }

    function test_multicall_revert() public {
        vm.prank(self, self);
        (bool success, ) = address(proxy).call{value: 1 ether}(abi.encodeCall(proxy.multicall, (new bytes[](0))));

        assertFalse(success);
    }
}
