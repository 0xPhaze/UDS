// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {LibERC1967ProxyWithImmutableArgs} from "../src/proxy/ERC1967ProxyWithImmutableArgs.sol";
import {MockUUPSUpgradeWithImmutableArgs} from "./mocks/MockUUPSUpgradeWithImmutableArgs.sol";

contract Logic is MockUUPSUpgradeWithImmutableArgs(1) {
    function bytes32Fn(
        bytes32 a,
        bytes32 b,
        bytes32 c
    )
        public
        pure
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (a, b, c, arg1(), arg2(), arg3());
    }

    function bytesFn(bytes calldata arg)
        public
        pure
        returns (
            bytes memory,
            bytes32,
            bytes32,
            bytes32
        )
    {
        return (arg, arg1(), arg2(), arg3());
    }
}

contract TestImmutableArgs is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    Logic logic;

    function setUp() public {
        logic = new Logic();
    }

    /* ------------- setUp() ------------- */

    /// test immutable args
    function testFuzz_args(
        bytes32 arg1,
        bytes32 arg2,
        bytes32 arg3
    ) public {
        bytes memory initCalldata = abi.encode(address(logic), "");

        Logic proxy1 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1));
        Logic proxy2 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1, arg2));
        Logic proxy3 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1, arg2, arg3));

        assertEq(proxy1.arg1(), arg1);

        assertEq(proxy2.arg1(), arg1);
        assertEq(proxy2.arg2(), arg2);

        assertEq(proxy3.arg1(), arg1);
        assertEq(proxy3.arg2(), arg2);
        assertEq(proxy3.arg3(), arg3);
    }

    /// make sure normal function args are still valid for bytesFn
    function testFuzz_bytesFn(
        bytes calldata data,
        bytes32 arg1,
        bytes32 arg2,
        bytes32 arg3
    ) public {
        bytes memory initCalldata = abi.encode(address(logic), "");

        Logic proxy1 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1));
        Logic proxy2 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1, arg2));
        Logic proxy3 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1, arg2, arg3));

        bytes32 arg1_;
        bytes32 arg2_;
        bytes32 arg3_;
        bytes memory data_;

        (data_, arg1_, , ) = proxy1.bytesFn(data);

        assertEq(arg1_, arg1);
        assertEq(keccak256(data_), keccak256(data));

        (data_, arg1_, arg2_, ) = proxy2.bytesFn(data);

        assertEq(arg1_, arg1);
        assertEq(arg2_, arg2);
        assertEq(keccak256(data_), keccak256(data));

        (data_, arg1_, arg2_, arg3_) = proxy3.bytesFn(data);

        assertEq(arg1_, arg1);
        assertEq(arg2_, arg2);
        assertEq(arg3_, arg3);
        assertEq(keccak256(data_), keccak256(data));
    }

    /// make sure normal function args are still valid for bytes32Fn
    function testFuzz_bytes32Fn(
        bytes32 fnArg1,
        bytes32 fnArg2,
        bytes32 fnArg3,
        bytes32 arg1,
        bytes32 arg2,
        bytes32 arg3
    ) public {
        bytes memory initCalldata = abi.encode(address(logic), "");

        {
            Logic proxy1 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1));

            (bytes32 fnArg1_, bytes32 fnArg2_, bytes32 fnArg3_, bytes32 arg1_, , ) = proxy1.bytes32Fn(
                fnArg1,
                fnArg2,
                fnArg3
            );

            assertEq(fnArg1_, fnArg1);
            assertEq(fnArg2_, fnArg2);
            assertEq(fnArg3_, fnArg3);
            assertEq(arg1_, arg1);
        }

        {
            Logic proxy2 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1, arg2));

            (bytes32 fnArg1_, bytes32 fnArg2_, bytes32 fnArg3_, bytes32 arg1_, bytes32 arg2_, ) = proxy2.bytes32Fn(
                fnArg1,
                fnArg2,
                fnArg3
            );

            assertEq(fnArg1_, fnArg1);
            assertEq(fnArg2_, fnArg2);
            assertEq(fnArg3_, fnArg3);
            assertEq(arg1_, arg1);
            assertEq(arg2_, arg2);
        }

        {
            Logic proxy3 = Logic(LibERC1967ProxyWithImmutableArgs.deploy(initCalldata, arg1, arg2, arg3));

            (bytes32 fnArg1_, bytes32 fnArg2_, bytes32 fnArg3_, bytes32 arg1_, bytes32 arg2_, bytes32 arg3_) = proxy3
                .bytes32Fn(fnArg1, fnArg2, fnArg3);

            assertEq(fnArg1_, fnArg1);
            assertEq(fnArg2_, fnArg2);
            assertEq(fnArg3_, fnArg3);
            assertEq(arg1_, arg1);
            assertEq(arg2_, arg2);
            assertEq(arg3_, arg3);
        }
    }
}

// re-run all tests in "./UUPSUpgrade.t.sol"
import {TestUUPSUpgrade, LogicV1, LogicV2} from "./UUPSUpgrade.t.sol";

contract TestUUPSUpgradeWithImmutableArgs is TestUUPSUpgrade {
    function setUp() public override {
        logicV1 = new LogicV1();
        logicV2 = new LogicV2();

        bytes memory initCalldata = abi.encode(address(logicV1), "");

        proxy = LibERC1967ProxyWithImmutableArgs.deploy(
            initCalldata,
            keccak256("arg1"),
            keccak256("arg2"),
            keccak256("arg3")
        );
    }
}
