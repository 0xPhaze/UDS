//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockUUPSUpgrade} from "./MockUUPSUpgrade.sol";
import "/tokens/ERC20UDS.sol";

contract MockERC20UDS is MockUUPSUpgrade(1), ERC20UDS {
    function init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __ERC20_init(_name, _symbol, _decimals);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }

    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }
}
