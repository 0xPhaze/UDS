// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {s as erc1967DS} from "../../proxy/ERC1967Proxy.sol";
import {UUPSUpgrade} from "../../proxy/UUPSUpgrade.sol";

contract MockUUPSUpgrade is UUPSUpgrade {
    uint256 public immutable version;

    constructor(uint256 version_) {
        version = version_;
    }

    function upgradeTo(address logic) external {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, "");
    }

    function implementation() public view returns (address) {
        return erc1967DS().implementation;
    }

    function scrambleStorage() public {
        unchecked {
            for (uint256 i; i < 100; i++) {
                assembly {
                    sstore(i, mul(0xba5696d68c5726256e84648c3a698d70c85973debbf507dacfa37f38bf49491e, i))
                }
            }
        }
    }

    function _authorizeUpgrade() internal virtual override {}
}
