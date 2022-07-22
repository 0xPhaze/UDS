// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1822, ERC1967_PROXY_STORAGE_SLOT, UPGRADED_EVENT_SIG} from "./ERC1967Proxy.sol";

error InvalidUUID();
error NotAContract();
error InvalidOffset(uint256 expected, uint256 actual);
error ExceedsMaxArgSize(uint256 size);

/// @title Library for deploying ERC1967 proxies with immutable args
/// @author phaze (https://github.com/0xPhaze/proxies-with-immutable-args)
/// @notice Inspired by (https://github.com/wighawag/clones-with-immutable-args)
/// @notice The implementation contract can be "read as a proxy" on etherscan
/// @dev Arguments are appended to calldata on any call
library LibERC1967ProxyWithImmutableArgs {
    /// @notice Deploys an ERC1967 proxy with immutable bytes args (max. 2^16 - 1 bytes)
    /// @notice This contract is not verifiable on etherscan
    /// @notice However, the proxy can be marked as a proxy
    /// @notice with "Read/Write as a proxy" tabs showing up on etherscan
    /// @param implementation address points to the implementation contract
    /// @param immutableArgs bytes array of immutable args
    /// @return addr address of the deployed proxy
    function deployProxyWithImmutableArgs(
        address implementation,
        bytes memory initCalldata,
        bytes memory immutableArgs
    ) internal returns (address addr) {
        verifyIsProxiableContract(implementation);

        bytes memory runtimeCode = proxyRuntimeCode(immutableArgs);
        bytes memory creationCode = proxyCreationCode(implementation, runtimeCode, initCalldata);

        assembly {
            addr := create(0, add(creationCode, 0x20), mload(creationCode))
        }

        if (addr.code.length == 0) revert();
    }

    /// @notice Reads a packed immutable arg with as bytes
    /// @param argOffset The offset of the arg in the packed data
    /// @param argLen The bytes length of the arg in the packed data
    /// @return arg The bytes arg value
    function getArgBytes(uint256 argOffset, uint256 argLen) internal pure returns (bytes memory arg) {
        uint256 offset = getImmutableArgsOffset();
        assembly {
            // position arg bytes at free memory position
            arg := mload(0x40)

            // store size
            mstore(arg, argLen)

            // copy data
            calldatacopy(add(arg, 0x20), add(offset, argOffset), argLen)

            // update free memmory pointer
            mstore(0x40, add(add(arg, 0x20), argLen))
        }
    }

    /// @notice Reads a packed immutable arg with as uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @param argLen The bytes length of the arg in the packed data
    /// @return arg The uint256 arg value
    function getArg(uint256 argOffset, uint256 argLen) internal pure returns (uint256 arg) {
        assembly {
            let sizeOffset := sub(calldatasize(), 2) // offset for size location
            let size := shr(240, calldataload(sizeOffset)) // immutableArgs bytes size
            let offset := sub(sizeOffset, size) // immutableArgs offset

            // load arg (in 32 bytes) and shift right by (256 - argLen * 8) bytes
            arg := shr(shl(3, sub(32, argLen)), calldataload(add(offset, argOffset)))

            // mask if trying to load too much calldata (argOffset + argLen > size)
            // should be users responsibility, though this makes testing easier
            let overload := shl(3, sub(add(argOffset, argLen), size))

            if lt(overload, 257) {
                arg := shl(overload, shr(overload, arg))
            }
        }
    }

    /// @notice Reads an immutable arg with type bytes32
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The bytes32 arg value
    function getArgBytes32(uint256 argOffset) internal pure returns (bytes32 arg) {
        return bytes32(getArg(argOffset, 32));
    }

    /// @notice Reads an immutable arg with type address
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The address arg value
    function getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = getImmutableArgsOffset();
        assembly {
            arg := shr(96, calldataload(add(offset, argOffset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The uint256 arg value
    function getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        return getArg(argOffset, 32);
    }

    /// @notice Reads an immutable arg with type uint128
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The uint128 arg value
    function getArgUint128(uint256 argOffset) internal pure returns (uint128 arg) {
        return uint128(getArg(argOffset, 16));
    }

    /// @notice Reads an immutable arg with type uint64
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The uint64 arg value
    function getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        return uint64(getArg(argOffset, 8));
    }

    /// @notice Reads an immutable arg with type uint40
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The uint40 arg value
    function getArgUint40(uint256 argOffset) internal pure returns (uint40 arg) {
        return uint40(getArg(argOffset, 5));
    }

    /// @notice Reads an immutable arg with type uint8
    /// @param argOffset The offset of the arg in the packed data
    /// @return arg The uint8 arg value
    function getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        return uint8(getArg(argOffset, 1));
    }

    /// @notice Gets the starting location in bytes in calldata for immutable args
    /// @return offset calldata bytes offset for immutable args
    function getImmutableArgsOffset() internal pure returns (uint256 offset) {
        assembly {
            let numBytes := shr(240, calldataload(sub(calldatasize(), 2)))
            offset := sub(sub(calldatasize(), 2), numBytes)
        }
    }

    /// @notice Gets the size in bytes of immutable args
    /// @return size bytes size of immutable args
    function getImmutableArgsLen() internal pure returns (uint256 size) {
        assembly {
            size := shr(240, calldataload(sub(calldatasize(), 2)))
        }
    }

    // ---------------------------------------------------------------------
    // Utils
    // ---------------------------------------------------------------------


    /// @notice Verifies that implementation contract conforms to ERC1967
    /// @notice This can be part of creationCode, but doesn't have to be
    /// @param implementation address containing the implementation logic
    function verifyIsProxiableContract(address implementation) internal view {
        if (implementation.code.length == 0) revert NotAContract();

        bytes32 uuid = ERC1822(implementation).proxiableUUID();

        if (uuid != ERC1967_PROXY_STORAGE_SLOT) revert InvalidUUID();
    }

    /// @dev Expects `implementation` (imp) to be on top of the stack
    /// @dev Must leave a copy of `implementation` (imp) on top of the stack
    /// @param pc program counter, used for calculating offsets
    function initCallcode(uint256 pc, bytes memory initCalldata) internal pure returns (bytes memory code) {
        uint256 initCalldataSize = initCalldata.length;

        code = abi.encodePacked(
            // push initCalldata to stack in 32 bytes chunks and store in memory at pos 0 

            MSTORE(0, initCalldata),                    // MSTORE icd       |                           | [0, ics) = initcalldata

            /// let success := delegatecall(gas(), implementation, 0, initCalldataSize, 0, 0)

            hex"3d"                                     // RETURNDATASIZE   | 00  imp                   | [0, ics) = initcalldata
            hex"3d",                                    // RETURNDATASIZE   | 00  00  imp               | [0, ics) = initcalldata
            PUSHX(initCalldataSize),                    // PUSHX ics        | ics 00  00  imp           | [0, ics) = initcalldata
            hex"3d"                                     // RETURNDATASIZE   | 00  ics 00  00  imp       | [0, ics) = initcalldata
            hex"84"                                     // DUP5             | imp 00  ics 00  00  imp   | [0, ics) = initcalldata
            hex"5a"                                     // GAS              | gas imp 00  ics 00  00  ..| [0, ics) = initcalldata
            hex"f4"                                     // DELEGATECALL     | scs imp                   | ...
        );

        // advance program counter
        pc += code.length;

        code = abi.encodePacked(code,
            /// if iszero(success) { revert(0, returndatasize()) }

            REVERT_ON_FAILURE(pc)                       //                  | imp                       | ...
        );
    }

    /// @notice Returns the creation code for an ERC1967 proxy with immutable args (max. 2^16 - 1 bytes)
    /// @param implementation address containing the implementation logic
    /// @param runtimeCode evm bytecode (runtime + concatenated extra data)
    /// @return creationCode evm bytecode that deploys ERC1967 proxy runtimeCode
    function proxyCreationCode(
        address implementation,
        bytes memory runtimeCode,
        bytes memory initCalldata
    ) internal pure returns (bytes memory creationCode) {
        uint256 pc; // program counter

        creationCode = abi.encodePacked(
            /// log2(0, 0, UPGRADED_EVENT_SIG, logic)

            hex"73", implementation,                    // PUSH20 imp       | imp
            hex"80"                                     // DUP1             | imp imp
            hex"7f", UPGRADED_EVENT_SIG,                // PUSH32 ues       | ues imp imp
            hex"3d"                                     // RETURNDATASIZE   | 00  ues imp imp
            hex"3d"                                     // RETURNDATASIZE   | 00  00  ues imp imp
            hex"a2"                                     // LOG2             | imp
        );

        pc = creationCode.length;

        // optional: insert code to call implementation contract with initCalldata during contract creation
        if (initCalldata.length != 0) {
            creationCode = abi.encodePacked(
                creationCode, 
                initCallcode(pc, initCalldata)
            );

            // update program counter
            pc = creationCode.length;
        }

        // PUSH1 is being used for storing runtimeSize
        if (runtimeCode.length > type(uint16).max) revert ExceedsMaxArgSize(runtimeCode.length);

        uint16 rts = uint16(runtimeCode.length);

        // runtimeOffset: runtime code location 
        //                = current pc + size of next block
        uint16 rto = uint16(pc + 45);

        creationCode = abi.encodePacked( creationCode,
            /// sstore(ERC1967_PROXY_STORAGE_SLOT, implementation)

            hex"7f", ERC1967_PROXY_STORAGE_SLOT,        // PUSH32 pss       | pss imp
            hex"55"                                     // SSTORE           | 

            /// codecopy(0, rto, rts)

            hex"61", rts,                               // PUSH2 rts        | rts
            hex"80"                                     // DUP1             | rts rts
            hex"61", rto,                               // PUSH2 rto        | rto rts rts
            hex"3d"                                     // RETURNDATASIZE   | 00  rto rts rts
            hex"39"                                     // CODECOPY         | rts                       | [00, rts) = runtimeCode + args

            /// return(0, rts)

            hex"3d"                                     // RETURNDATASIZE   | 00  rts
            hex"f3"                                     // RETURN
        ); // prettier-ignore

        pc = creationCode.length;

        // sanity check for runtime location parameter
        if (pc != rto) revert InvalidOffset(rto, creationCode.length);

        creationCode = abi.encodePacked(creationCode, runtimeCode);
    }

    /// @notice Returns the runtime code for an ERC1967 proxy with immutable args (max. 2^16 - 1 bytes)
    /// @param args immutable args byte array
    /// @return runtimeCode evm bytecode
    function proxyRuntimeCode(bytes memory args) internal pure returns (bytes memory runtimeCode) {
        uint16 extraDataSize = uint16(args.length) + 2; // 2 extra bytes for the storing the size of the args

        uint8 argsCodeOffset = 0x48; // length of the runtime code

        uint8 returnJumpLocation = argsCodeOffset - 5;

        // @note: uses codecopy, room to optimize by directly encoding immutableArgs into bytecode
        runtimeCode = abi.encodePacked(
            /// calldatacopy(0, 0, calldatasize())

            hex"36"                                     // CALLDATASIZE     | cds                       |
            hex"3d"                                     // RETURNDATASIZE   | 00  cds                   |
            hex"3d"                                     // RETURNDATASIZE   | 00  00  cds               |
            hex"37"                                     // CALLDATACOPY     |                           | [0, cds) = calldata

            /// codecopy(calldatasize(), argsCodeOffset, extraDataSize)

            hex"61", extraDataSize,                     // PUSH2 xds        | xds                       | [0, cds) = calldata
            hex"60", argsCodeOffset,                    // PUSH1 aco        | aco xds                   | [0, cds) = calldata
            hex"36"                                     // CALLDATASIZE     | cds aco xds               | [0, cds) = calldata
            hex"39"                                     // CODECOPY         |                           | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)

            /// tcs := add(calldatasize(), extraDataSize)
            hex"3d"                                     // RETURNDATASIZE   | 00                        | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)
            hex"3d"                                     // RETURNDATASIZE   | 00  00                    | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)
            hex"61", extraDataSize,                     // PUSH2 xds        | xds 00  00                | [0, cds) = calldata
            hex"36"                                     // CALLDATASIZE     | cds xds 00  00            | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)
            hex"01"                                     // ADD              | tcs 00  00                | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)

            /// success := delegatecall(gas(), sload(ERC1967_PROXY_STORAGE_SLOT), 0, tcs, 0, 0)

            hex"3d"                                     // RETURNDATASIZE   | 00  tcs 00  00            | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)
            hex"7f", ERC1967_PROXY_STORAGE_SLOT,        // PUSH32 pss       | pss 00  tcs 00 00         | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)
            hex"54"                                     // SLOAD            | pxa 00  tcs 00  00        | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)
            hex"5a"                                     // GAS              | gas pxa 00  tcs 00  00    | [0, cds) = calldata, [cds, cds + xds] = args + byte2(argSize)
            hex"f4"                                     // DELEGATECALL     | scs                       | ...

            /// returndatacopy(0, 0, returndatasize())

            hex"3d"                                     // RETURNDATASIZE   | rds scs                   | ...
            hex"60" hex"00"                             // PUSH1 00         | 00  rds scs               | ...
            hex"80"                                     // DUP1             | 00  00  rds scs           | ...
            hex"3e"                                     // RETURNDATACOPY   | scs                       | [0, rds) = returndata

            /// if success { jump(rtn) }

            hex"60", returnJumpLocation,                // PUSH1 rtn        | rtn scs                   | [0, rds) = returndata
            hex"57"                                     // JUMPI            |                           | [0, rds) = returndata

            /// revert(0, returndatasize())

            hex"3d"                                     // RETURNDATASIZE   | rds                       | [0, rds) = returndata
            hex"60" hex"00"                             // PUSH1 00         | 00  rds                   | [0, rds) = returndata
            hex"fd"                                     // REVERT           |                           | 

            /// return(0, returndatasize())

            hex"5b"                                     // JUMPDEST         |                           | [0, rds) = returndata
            hex"3d"                                     // RETURNDATASIZE   | rds                       | [0, rds) = returndata
            hex"60" hex"00"                             // PUSH1 00         | 00  rds                   | [0, rds) = returndata
            hex"f3",                                    // RETURN           |                           | ...

            // unreachable code: 
            // append args and args length for later use

            args,
            uint16(args.length)

        ); // prettier-ignore

        // just a sanity check for for jump locations
        if (runtimeCode.length != argsCodeOffset + extraDataSize) revert InvalidOffset(argsCodeOffset, runtimeCode.length);
    }

    // ---------------------------------------------------------------------
    // Snippets
    // ---------------------------------------------------------------------

    /// @notice expects call `success` (scs) bool to be on top of stack
    function REVERT_ON_FAILURE(uint256 pc) internal pure returns (bytes memory code) {
        // upper bound for when end location requires 32 bytes
        uint256 pushNumBytes = getRequiredBytes(pc + 38);
        uint256 end = pc + pushNumBytes + 11;

        code = abi.encodePacked(
            /// if success { jump(end) }

            PUSHX(end, pushNumBytes),                   // PUSH1 end        | end scs 
            hex"57"                                     // JUMPI            |         

            /// returndatacopy(0, 0, returndatasize())

            hex"3d"                                     // RETURNDATASIZE   | rds                       | ...
            hex"60" hex"00"                             // PUSH1 00         | 00  rds                   | ...
            hex"80"                                     // DUP1             | 00  00  rds               | ...
            hex"3e"                                     // RETURNDATACOPY   |                           | [0, rds) = returndata

            /// revert(0, returndatasize())

            hex"3d"                                     // RETURNDATASIZE   | rds    
            hex"60" hex"00"                             // PUSH1 00         | 00  rds
            hex"fd"                                     // REVERT           |        

            hex"5b"                                     // JUMPDEST         | 
        );
    }

    /// @notice expects call `success` (scs) bool to be on top of stack
    /// @notice using this for testing
    // apparently you can't revert any returndata 
    // messages when using CREATE (returndatasize() is always 0)
    // that's why I'm encoding it in the returndata
    function RETURN_REVERT_REASON_ON_FAILURE_TEST(uint256 pc) internal pure returns (bytes memory code) {
        // upper bound for when end location requires 32 bytes
        uint256 pushNumBytes = getRequiredBytes(pc + 38);

        // jump location to continue in code
        uint256 end = pc + pushNumBytes + 19;

        code = abi.encodePacked(
            /// if success { jump(end) }

            PUSHX(end, pushNumBytes),                   // PUSH1 end        | end scs 
            hex"57"                                     // JUMPI            |         

            /// mstore(0, 0)

            hex"60" hex"00"                             // PUSH1 00         | 00
            hex"80"                                     // DUP1 80          | 80  00
            hex"52"                                     // MSTORE           |                           | [0] = 00 (STOP opcode; identifier for encoding reverted call reason)


            /// returndatacopy(1, 0, returndatasize())

            hex"3d"                                     // RETURNDATASIZE   | rds                       | [0] = 00
            hex"60" hex"00"                             // PUSH1 00         | 00  rds                   | [0] = 00
            hex"60" hex"01"                             // PUSH1 01         | 01  00  rds               | [0] = 00
            hex"3e"                                     // RETURNDATACOPY   |                           | [0] = 00


            /// return(0, 1 + returndatasize())

            hex"3d"                                     // RETURNDATASIZE   | rds                       | [0, rds + 20) = encoded revert reason
            hex"60" hex"01"                             // PUSH1 01         | 01  rds                   | [0, rds + 20) = encoded revert reason
            hex"01"                                     // ADD              | eds                       | [0, rds + 20) = encoded revert reason
            hex"60" hex"00"                             // PUSH1 00         | 00  eds
            hex"f3"                                     // RETURN           |        

            hex"5b"                                     // JUMPDEST         | 
        );

        // sanity check
        if (end + 1 !=  pc + code.length) revert InvalidOffset(end + 1, pc + code.length);
    }


    /// @notice Mstore that copies bytes to memory offset in chunks of 32
    function MSTORE(uint256 offset, bytes memory data) internal pure returns (bytes memory code) {

        bytes32[] memory bytes32Data = splitToBytes32(data);

        uint256 numChunks = bytes32Data.length;

        for (uint256 i; i < numChunks; i++) {
            code = abi.encodePacked( code,
                /// mstore(offset + i * 32, bytes32Data[i])

                hex"7f", bytes32Data[i],                // PUSH32 data      | data
                PUSHX(offset + i * 32),                 // PUSHX off        | off data
                hex"52"                                 // MSTORE           |

            ); // prettier-ignore
        }
    }

    function PUSHX(uint256 value) internal pure returns (bytes memory code) {
        return PUSHX(value, getRequiredBytes(value));
    }

    /// @notice Pushes value with the least required bytes onto stack
    /// @notice Probably overkill...
    function PUSHX(uint256 value, uint256 numBytes) internal pure returns (bytes memory code) {
        if (numBytes == 1) code = abi.encodePacked(hex"60", uint8(value));
        else if (numBytes == 2) code = abi.encodePacked(hex"61", uint16(value));
        else if (numBytes == 3) code = abi.encodePacked(hex"62", uint24(value));
        else if (numBytes == 4) code = abi.encodePacked(hex"63", uint32(value));
        else if (numBytes == 5) code = abi.encodePacked(hex"64", uint40(value));
        else if (numBytes == 6) code = abi.encodePacked(hex"65", uint48(value));
        else if (numBytes == 7) code = abi.encodePacked(hex"66", uint56(value));
        else if (numBytes == 8) code = abi.encodePacked(hex"67", uint64(value));
        else if (numBytes == 9) code = abi.encodePacked(hex"68", uint72(value));
        else if (numBytes == 10) code = abi.encodePacked(hex"69", uint80(value));
        else if (numBytes == 11) code = abi.encodePacked(hex"6a", uint88(value));
        else if (numBytes == 12) code = abi.encodePacked(hex"6b", uint96(value));
        else if (numBytes == 13) code = abi.encodePacked(hex"6c", uint104(value));
        else if (numBytes == 14) code = abi.encodePacked(hex"6d", uint112(value));
        else if (numBytes == 15) code = abi.encodePacked(hex"6e", uint120(value));
        else if (numBytes == 16) code = abi.encodePacked(hex"6f", uint128(value));
        else if (numBytes == 17) code = abi.encodePacked(hex"70", uint136(value));
        else if (numBytes == 18) code = abi.encodePacked(hex"71", uint144(value));
        else if (numBytes == 19) code = abi.encodePacked(hex"72", uint152(value));
        else if (numBytes == 20) code = abi.encodePacked(hex"73", uint160(value));
        else if (numBytes == 21) code = abi.encodePacked(hex"74", uint168(value));
        else if (numBytes == 22) code = abi.encodePacked(hex"75", uint176(value));
        else if (numBytes == 23) code = abi.encodePacked(hex"76", uint184(value));
        else if (numBytes == 24) code = abi.encodePacked(hex"77", uint192(value));
        else if (numBytes == 25) code = abi.encodePacked(hex"78", uint200(value));
        else if (numBytes == 26) code = abi.encodePacked(hex"79", uint208(value));
        else if (numBytes == 27) code = abi.encodePacked(hex"7a", uint216(value));
        else if (numBytes == 28) code = abi.encodePacked(hex"7b", uint224(value));
        else if (numBytes == 29) code = abi.encodePacked(hex"7c", uint232(value));
        else if (numBytes == 30) code = abi.encodePacked(hex"7d", uint240(value));
        else if (numBytes == 31) code = abi.encodePacked(hex"7e", uint248(value));
        else if (numBytes == 32) code = abi.encodePacked(hex"7f", uint256(value));
    }

        /// @notice split data to chunks of 32 bytes
    function splitToBytes32(bytes memory data) internal pure returns (bytes32[] memory split) {
        uint256 numEl = (data.length + 31) >> 5;

        split = new bytes32[](numEl);

        uint256 loc;

        assembly {
            loc := add(split, 32)
        }

        mstore(loc, data);
    }

    /// @notice stores data at offset while preserving existing memory
    function mstore(uint256 offset, bytes memory data) internal pure {
        uint256 slot;

        uint256 size = data.length;

        uint256 lastFullSlot = size >> 5;

        for (; slot < lastFullSlot; slot++) {
            assembly {
                let rel_ptr := mul(slot, 32)
                let chunk := mload(add(add(data, 32), rel_ptr))
                mstore(add(offset, rel_ptr), chunk)
            }
        }

        assembly {
            let mask := shr(shl(3, and(size, 31)), sub(0, 1))
            let rel_ptr := mul(slot, 32)
            let chunk := mload(add(add(data, 32), rel_ptr))
            let prev_data := mload(add(offset, rel_ptr))
            mstore(add(offset, rel_ptr), or(and(chunk, not(mask)), and(prev_data, mask)))
        }
    }

    /// @notice gets minimum required bytes to store value
    function getRequiredBytes(uint256 value) internal pure returns (uint256) {
        uint256 numBytes = 1;

        for (; numBytes < 32; ++numBytes) {
            value = value >> 8;
            if (value == 0) break;
        }

        return numBytes;
    }
}
