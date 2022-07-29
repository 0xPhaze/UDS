//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockUUPSUpgrade} from "./MockUUPSUpgrade.sol";
import "UDS/tokens/ERC20RewardUDS.sol";

contract MockERC20RewardUDS is MockUUPSUpgrade, ERC20RewardUDS {
    uint256 immutable rate;
    uint256 immutable end;

    constructor(uint256 rate_, uint256 end_) {
        rate = rate_;
        end = end_;
    }

    /* ------------- init ------------- */

    function init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __ERC20_init(_name, _symbol, _decimals);
    }

    /* ------------- view ------------- */

    function rewardEndDate() public view override returns (uint256) {
        return end;
    }

    function rewardDailyRate() public view override returns (uint256) {
        return rate;
    }

    function getMultiplier(address owner) public view returns (uint256) {
        return s().userData[owner].multiplier;
    }

    function getLastClaimed(address owner) public view returns (uint256) {
        return s().userData[owner].lastClaimed;
    }

    /* ------------- public ------------- */

    function burn(address from, uint256 value) public {
        _burn(from, value);
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function increaseMultiplier(address owner, uint216 quantity) public {
        _increaseRewardMultiplier(owner, quantity);
    }

    function decreaseMultiplier(address owner, uint216 quantity) public {
        _decreaseRewardMultiplier(owner, quantity);
    }

    function claimReward() public {
        _claimReward(msg.sender);
    }
}
