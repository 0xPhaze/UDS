//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgrade} from "../../proxy/UUPSUpgrade.sol";
import "../../ERC20UDS.sol";

contract MockERC20UDS is UUPSUpgrade, ERC20UDS {
    function init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __ERC20UDS_init(_name, _symbol, _decimals);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    function _authorizeUpgrade() internal virtual override {}
}
