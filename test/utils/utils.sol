// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {console} from "forge-std/Test.sol";

library utils {
    function mdump(uint256 location, uint256 numSlots) internal view {
        bytes32 m;
        for (uint256 i; i < numSlots; i++) {
            assembly {
                m := mload(add(location, mul(32, i)))
            }
            console.log(location, 32 * i);
            console.logBytes32(m);
        }
    }

    function mdump(bytes memory arg) internal view {
        mdump(mloc(arg), (arg.length + 1) / 32 + 1);
    }

    function mdump(bytes32[] memory arg) internal view {
        mdump(mloc(arg), arg.length + 1);
    }

    function mloc(bytes memory arr) internal pure returns (uint256 loc) {
        assembly {
            loc := arr
        }
    }

    function mloc(bytes32[] memory arr) internal pure returns (uint256 loc) {
        assembly {
            loc := arr
        }
    }

    function scrambleMem(bytes32[] memory arr) internal pure {
        return scrambleMem(mloc(arr) + 32, arr.length * 32);
    }

    function scrambleMem(uint256 offset, uint256 bytesLen) internal pure {
        uint256 slot;
        bytes32 rand;

        uint256 lastFullSlot = bytesLen >> 5;

        for (; slot < lastFullSlot; slot++) {
            rand = keccak256(abi.encodePacked(slot));

            assembly {
                mstore(add(offset, mul(slot, 32)), rand)
            }
        }

        uint256 mask = type(uint256).max >> ((bytesLen & 31) << 3);

        rand = keccak256(abi.encodePacked(slot));

        assembly {
            let location := add(offset, mul(slot, 32))
            let data := mload(location)
            mstore(location, or(and(data, mask), and(rand, not(mask))))
        }
    }

    function scrambleStorage(uint256 offset, uint256 numSlots) public {
        bytes32 rand;
        for (uint256 slot; slot < numSlots; slot++) {
            rand = keccak256(abi.encodePacked(offset + slot));

            assembly {
                sstore(add(slot, offset), rand)
            }
        }
    }

    function mstore(
        uint256 offset,
        bytes32 val,
        uint256 bytesLen
    ) internal pure {
        assembly {
            let mask := shr(mul(bytesLen, 8), sub(0, 1))
            mstore(offset, or(and(val, not(mask)), and(mload(offset), mask)))
        }
    }
}
