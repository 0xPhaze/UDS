// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializableUDS} from "../auth/InitializableUDS.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";
import {ERC20UDS, s as erc20DS} from "./ERC20UDS.sol";

// ------------- storage

// keccak256("diamond.storage.erc20.drip") == 0x8c757391584fa5c5dc065e485ac4f0a50a060fb8660a0046bb8d8210b4088636;
bytes32 constant DIAMOND_STORAGE_ERC20_DRIP = 0x8c757391584fa5c5dc065e485ac4f0a50a060fb8660a0046bb8d8210b4088636;

function s() pure returns (ERC20DripDS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ERC20_DRIP } // prettier-ignore
}

struct DripData {
    uint216 multiplier;
    uint40 lastClaimed;
}

struct ERC20DripDS {
    mapping(address => DripData) dripData;
}

/// @title ERC20Drip (Upgradeable Diamond Storage, ERC20 compliant)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @author Named after DRIP20 (https://github.com/0xBeans/DRIP20)
/// @notice Allows for directly "dripping" ERC20 tokens into a user's wallet
/// @notice at a rate of dripDailyRate() * multiplier[user] per day
/// @notice Tokens are automatically claimed before any balance update
abstract contract ERC20DripUDS is ERC20UDS {
    /* ------------- public ------------- */

    function dripDailyRate() public view virtual returns (uint256);

    function dripStartDate() public view virtual returns (uint256);

    function dripEndDate() public view virtual returns (uint256);

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return super.balanceOf(owner) + _virtualBalanceOf(owner);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _claimVirtualBalance(msg.sender);

        return super.transfer(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _claimVirtualBalance(from);

        return super.transferFrom(from, to, amount);
    }

    /* ------------- internal ------------- */

    function _getDripMultiplier(address owner) internal view returns (uint256) {
        return s().dripData[owner].multiplier;
    }

    function _virtualBalanceOf(address owner) internal view virtual returns (uint256) {
        DripData storage dripData = s().dripData[owner];

        return _calculateDripBalance(dripData.multiplier, dripData.lastClaimed);
    }

    function _calculateDripBalance(uint256 multiplier, uint256 lastClaimed) internal view virtual returns (uint256) {
        if (multiplier == 0) return 0;

        uint256 start = dripStartDate();
        uint256 end = dripEndDate();

        uint256 timestamp = block.timestamp;

        if (timestamp < start) return 0;
        else if (timestamp > end) timestamp = end;
        // => timestamp in [start, end]

        if (lastClaimed < start) lastClaimed = start;
        else if (lastClaimed > end) return 0;
        // => lastClaimed in [start, end]

        return ((timestamp - lastClaimed) * multiplier * dripDailyRate()) / 1 days;
    }

    function _claimVirtualBalance(address owner) internal virtual {
        DripData storage dripData = s().dripData[owner];

        uint256 multiplier = dripData.multiplier;

        if (multiplier != 0) {
            uint256 amount = _calculateDripBalance(multiplier, dripData.lastClaimed);

            _mint(owner, amount);

            s().dripData[owner].lastClaimed = uint40(block.timestamp);
        }
    }

    function _increaseDripMultiplier(address owner, uint216 quantity) internal {
        _claimVirtualBalance(owner);

        s().dripData[owner].multiplier += uint216(quantity);
    }

    function _decreaseDripMultiplier(address owner, uint216 quantity) internal {
        _claimVirtualBalance(owner);

        s().dripData[owner].multiplier -= uint216(quantity);
    }
}
