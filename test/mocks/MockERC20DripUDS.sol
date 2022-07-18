//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockUUPSUpgrade} from "./MockUUPSUpgrade.sol";
import "/tokens/ERC20DripUDS.sol";

contract MockERC20DripUDS is MockUUPSUpgrade(1), ERC20DripUDS {
    uint256 immutable rate;
    uint256 immutable end;

    constructor(uint256 rate_, uint256 end_) {
        rate = rate_;
        end = end_;
    }

    function dripDailyRate() public view override returns (uint256) {
        return rate;
    }

    function dripEndDate() public view override returns (uint256) {
        return end;
    }

    function init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external initializer {
        __ERC20UDS_init(_name, _symbol, _decimals);
    }

    /* ------------- view ------------- */

    function getMultiplier(address owner) public view returns (uint256) {
        return s().dripData[owner].multiplier;
    }

    function getLastClaimed(address owner) public view returns (uint256) {
        return s().dripData[owner].lastClaimed;
    }

    /* ------------- public ------------- */

    function burn(address from, uint256 value) public {
        _burn(from, value);
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function increaseMultiplier(address owner, uint216 quantity) public {
        _increaseDripMultiplier(owner, quantity);
    }

    function decreaseMultiplier(address owner, uint216 quantity) public {
        _decreaseDripMultiplier(owner, quantity);
    }

    function claimVirtualBalance() public {
        _claimVirtualBalance(msg.sender);
    }

    function virtualBalanceOf(address owner) public view returns (uint256) {
        return _virtualBalanceOf(owner);
    }
}
