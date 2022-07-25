// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967_PROXY_STORAGE_SLOT} from "UDS/proxy/ERC1967Proxy.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";

contract MockUUPSUpgrade is UUPSUpgrade {
    function implementation() public view returns (address impl) {
        assembly {
            impl := sload(ERC1967_PROXY_STORAGE_SLOT)
        }
    }

    function forceUpgrade(address impl) public {
        assembly {
            sstore(ERC1967_PROXY_STORAGE_SLOT, impl)
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

    function _authorizeUpgrade() internal virtual override {}
}
