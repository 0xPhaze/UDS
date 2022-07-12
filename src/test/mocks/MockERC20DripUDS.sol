//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MockUUPSUpgrade} from "./MockUUPSUpgrade.sol";
import "../../ERC20DripUDS.sol";

contract MockERC20DripUDS is MockUUPSUpgrade(1), ERC20DripUDS {
    uint256 internal immutable dripRate;
    uint256 internal immutable _dripStart = block.timestamp;

    constructor(uint256 rate) {
        dripRate = rate;
    }

    function dripDailyRate() public view override returns (uint256) {
        return dripRate;
    }

    function dripStart() public view override returns (uint256) {
        return _dripStart;
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
        _increaseMultiplier(owner, quantity);
    }

    function decreaseMultiplier(address owner, uint216 quantity) public {
        _decreaseMultiplier(owner, quantity);
    }

    function claimVirtualBalance() public {
        _claimVirtualBalance(msg.sender);
    }

    function virtualBalanceOf(address owner) public view returns (uint256) {
        return _virtualBalanceOf(owner);
    }
}
