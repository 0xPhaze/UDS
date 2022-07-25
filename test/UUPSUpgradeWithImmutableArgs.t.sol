// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {LibERC1967ProxyWithImmutableArgs} from "UDS/proxy/LibERC1967ProxyWithImmutableArgs.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

// ---------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------

contract MockBase {
    uint256 immutable argOffset;
    uint256 immutable argLen;

    constructor(uint256 argOffset_, uint256 argLen_) {
        argOffset = argOffset_;
        argLen = argLen_;
    }
}

contract MockGetMsgData {
    fallback() external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            return(0, calldatasize())
        }
    }
}

contract MockGetImmutableArgsLen {
    fallback() external payable {
        uint256 size = LibERC1967ProxyWithImmutableArgs.getImmutableArgsLen();
        assembly {
            mstore(0, size)
            return(0, 0x20)
        }
    }
}

contract MockGetImmutableArgsOffset {
    fallback() external payable {
        uint256 offset = LibERC1967ProxyWithImmutableArgs.getImmutableArgsOffset();
        assembly {
            mstore(0, offset)
            return(0, 0x20)
        }
    }
}

contract MockGetArgBytes is MockBase {
    constructor(uint256 argOffset, uint256 argLen) MockBase(argOffset, argLen) {}

    fallback() external payable {
        bytes memory arg = LibERC1967ProxyWithImmutableArgs.getArgBytes(argOffset, argLen);

        assembly {
            return(add(arg, 0x20), mload(arg))
        }
    }
}

contract MockGetArgBytes32 is MockBase {
    constructor(uint256 argOffset, uint256 argLen) MockBase(argOffset, argLen) {}

    fallback() external payable {
        bytes32 arg = LibERC1967ProxyWithImmutableArgs.getArgBytes32(argOffset);

        assembly {
            mstore(0, arg)
            return(0, 0x20)
        }
    }
}

contract MockGetArgUint256 is MockBase {
    constructor(uint256 argOffset, uint256 argLen) MockBase(argOffset, argLen) {}

    fallback() external payable {
        uint256 arg = LibERC1967ProxyWithImmutableArgs.getArgUint256(argOffset);

        assembly {
            mstore(0, arg)
            return(0, 0x20)
        }
    }
}

contract MockGetArgUint128 is MockBase {
    constructor(uint128 argOffset, uint128 argLen) MockBase(argOffset, argLen) {}

    fallback() external payable {
        uint128 arg = LibERC1967ProxyWithImmutableArgs.getArgUint128(argOffset);

        assembly {
            mstore(0, arg)
            return(0, 0x20)
        }
    }
}

contract MockGetArgUint64 is MockBase {
    constructor(uint256 argOffset, uint256 argLen) MockBase(argOffset, argLen) {}

    fallback() external payable {
        uint64 arg = LibERC1967ProxyWithImmutableArgs.getArgUint64(argOffset);

        assembly {
            mstore(0, arg)
            return(0, 0x20)
        }
    }
}

contract MockGetArgUint40 is MockBase {
    constructor(uint256 argOffset, uint256 argLen) MockBase(argOffset, argLen) {}

    fallback() external payable {
        uint40 arg = LibERC1967ProxyWithImmutableArgs.getArgUint40(argOffset);

        assembly {
            mstore(0, arg)
            return(0, 0x20)
        }
    }
}

contract MockGetArgUint8 is MockBase {
    constructor(uint256 argOffset, uint256 argLen) MockBase(argOffset, argLen) {}

    fallback() external payable {
        uint8 arg = LibERC1967ProxyWithImmutableArgs.getArgUint8(argOffset);

        assembly {
            mstore(0, arg)
            return(0, 0x20)
        }
    }
}

// ---------------------------------------------------------------------
// Immutable Args Tests
// ---------------------------------------------------------------------

contract TestImmutableArgs is Test {
    address logic;

    function setUp() public {
        logic = address(new MockUUPSUpgrade());
    }

    /* ------------- helpers ------------- */

    function boundParameterRange(
        uint256 immutableArgsLen,
        uint256 readArgOffset,
        uint256 readArgLen
    ) internal pure returns (uint16, uint16) {
        readArgOffset %= immutableArgsLen + 1;
        readArgLen %= immutableArgsLen + 1 - readArgOffset;

        return (uint16(readArgOffset), uint16(readArgLen));
    }

    function expectReturnedArg(
        address proxy,
        bytes calldata randomCalldata,
        bytes calldata immutableArgs,
        uint256 readArgOffset,
        uint256 readArgLen
    ) internal {
        (, bytes memory returndata) = address(proxy).call(randomCalldata);

        bytes32 returnedArg = abi.decode(returndata, (bytes32));

        bytes32 expectedArg;

        assembly {
            expectedArg := calldataload(add(immutableArgs.offset, readArgOffset))
            expectedArg := shr(shl(3, sub(32, readArgLen)), expectedArg)
        }

        assertEq(returnedArg, expectedArg);
    }

    /* ------------- tests ------------- */

    function test_getMsgData(bytes memory randomCalldata, bytes memory immutableArgs) public {
        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetMsgData()));

        (, bytes memory returndata) = address(proxy).call(randomCalldata);

        assertEq(returndata, abi.encodePacked(randomCalldata, immutableArgs, uint16(immutableArgs.length)));
    }

    function test_getArgsLen(bytes memory randomCalldata, bytes memory immutableArgs) public {
        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetImmutableArgsLen()));

        (, bytes memory returndata) = address(proxy).call(randomCalldata);

        uint256 len = abi.decode(returndata, (uint256));

        assertEq(len, immutableArgs.length);
    }

    function test_getArgsOffset(bytes memory randomCalldata, bytes memory immutableArgs) public {
        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetImmutableArgsOffset()));

        (, bytes memory returndata) = address(proxy).call(randomCalldata);

        uint256 offset = abi.decode(returndata, (uint256));

        assertEq(offset, randomCalldata.length);
    }

    function test_getArgBytes(
        bytes calldata randomCalldata,
        bytes calldata immutableArgs,
        uint16 readArgOffset,
        uint16 readArgLen
    ) public {
        (readArgOffset, readArgLen) = boundParameterRange(immutableArgs.length, readArgOffset, readArgLen);

        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetArgBytes(readArgOffset, readArgLen)));

        (, bytes memory returndata) = address(proxy).call(randomCalldata);

        assertEq(returndata, immutableArgs[readArgOffset:readArgOffset + readArgLen]);
    }

    function test_getArgBytes32(
        uint16 readArgOffset,
        bytes calldata randomCalldata,
        bytes calldata immutableArgs
    ) public {
        uint16 readArgLen = 32;

        (readArgOffset, ) = boundParameterRange(immutableArgs.length, readArgOffset, 0);

        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetArgBytes32(readArgOffset, readArgLen)));

        expectReturnedArg(proxy, randomCalldata, immutableArgs, readArgOffset, readArgLen);
    }

    function test_getArgUint256(
        uint16 readArgOffset,
        bytes calldata randomCalldata,
        bytes calldata immutableArgs
    ) public {
        uint16 readArgLen = 32;

        (readArgOffset, ) = boundParameterRange(immutableArgs.length, readArgOffset, 0);

        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetArgUint256(readArgOffset, readArgLen)));

        expectReturnedArg(proxy, randomCalldata, immutableArgs, readArgOffset, readArgLen);
    }

    function test_getArgUint128(
        uint16 readArgOffset,
        bytes calldata randomCalldata,
        bytes calldata immutableArgs
    ) public {
        uint16 readArgLen = 16;

        (readArgOffset, ) = boundParameterRange(immutableArgs.length, readArgOffset, 0);

        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetArgUint128(readArgOffset, readArgLen)));

        expectReturnedArg(proxy, randomCalldata, immutableArgs, readArgOffset, readArgLen);
    }

    function test_getArgUint64(
        uint16 readArgOffset,
        bytes calldata randomCalldata,
        bytes calldata immutableArgs
    ) public {
        uint16 readArgLen = 8;

        (readArgOffset, ) = boundParameterRange(immutableArgs.length, readArgOffset, 0);

        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetArgUint64(readArgOffset, readArgLen)));

        expectReturnedArg(proxy, randomCalldata, immutableArgs, readArgOffset, readArgLen);
    }

    function test_getArgUint40(
        uint16 readArgOffset,
        bytes calldata randomCalldata,
        bytes calldata immutableArgs
    ) public {
        uint16 readArgLen = 5;

        (readArgOffset, ) = boundParameterRange(immutableArgs.length, readArgOffset, 0);

        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetArgUint40(readArgOffset, readArgLen)));

        expectReturnedArg(proxy, randomCalldata, immutableArgs, readArgOffset, readArgLen);
    }

    function test_getArgUint8(
        uint16 readArgOffset,
        bytes calldata randomCalldata,
        bytes calldata immutableArgs
    ) public {
        uint16 readArgLen = 1;

        (readArgOffset, ) = boundParameterRange(immutableArgs.length, readArgOffset, 0);

        address proxy = LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(logic, "", immutableArgs);

        MockUUPSUpgrade(proxy).forceUpgrade(address(new MockGetArgUint8(readArgOffset, readArgLen)));

        expectReturnedArg(proxy, randomCalldata, immutableArgs, readArgOffset, readArgLen);
    }
}

// ---------------------------------------------------------------------
// re-run all tests from "./UUPSUpgrade.t.sol" for proxy with immutable args
// - these tests need to be run from a `Deployer` contract,
//   so that forge can catch the reverts on external calls
// ---------------------------------------------------------------------

import {TestUUPSUpgrade} from "./UUPSUpgrade.t.sol";

contract ProxyTestDeployer {
    function deployProxyWithImmutableArgs(
        address implementation,
        bytes memory initCalldata,
        bytes memory immutableArgs
    ) public returns (address) {
        return
            LibERC1967ProxyWithImmutableArgs.deployProxyWithImmutableArgs(implementation, initCalldata, immutableArgs);
    }
}

contract TestUUPSUpgradeWithImmutableArgs is TestUUPSUpgrade {
    ProxyTestDeployer deployer;

    function setUp() public override {
        deployer = new ProxyTestDeployer();
        super.setUp();
    }

    function deployProxyAndCall(address implementation, bytes memory initCalldata) internal override returns (address) {
        return
            deployer.deployProxyWithImmutableArgs(
                implementation,
                initCalldata,
                abi.encode(keccak256("arg1"), keccak256("arg2"), keccak256("arg3"))
            );
    }
}
