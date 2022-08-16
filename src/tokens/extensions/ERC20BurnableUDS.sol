// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20UDS, s as erc20ds} from "../ERC20UDS.sol";

/// @title ERC20Burnable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @notice Allows for burning ERC20 tokens
abstract contract ERC20BurnableUDS is ERC20UDS {
    /* ------------- public ------------- */

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address from, uint256 amount) public virtual {
        if (_msgSender() != from) {
            uint256 allowed = erc20ds().allowance[from][_msgSender()];

            if (allowed != type(uint256).max) erc20ds().allowance[from][_msgSender()] = allowed - amount;
        }

        _burn(from, amount);
    }
}
