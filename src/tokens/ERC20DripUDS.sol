// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20RewardsUDS} from "./ERC20RewardsUDS.sol";
import {ERC20UDS} from "./ERC20UDS.sol";

/// @title ERC20Drip (Upgradeable Diamond Storage, ERC20 compliant)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Named after DRIP20 (https://github.com/0xBeans/DRIP20)
/// @notice Allows for directly "dripping" ERC20 tokens into a user's wallet
/// @notice at a rate of rewardDailyRate() * multiplier[user] per day
/// @notice Tokens are automatically claimed before any balance update
abstract contract ERC20DripUDS is ERC20RewardsUDS {
    /* ------------- virtual ------------- */

    function rewardEndDate() public view virtual override returns (uint256);

    function rewardDailyRate() public view virtual override returns (uint256);

    /* ------------- public ------------- */

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return ERC20UDS.balanceOf(owner) + _virtualBalanceOf(owner);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _claimVirtualBalance(msg.sender);

        return ERC20UDS.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _claimVirtualBalance(from);

        return ERC20UDS.transferFrom(from, to, amount);
    }
}
