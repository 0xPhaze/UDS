// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";
import {EIP712PermitUDS} from "./EIP712PermitUDS.sol";
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

/// @notice ERC20Drip compatible with diamond storage
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
/// @author Inspired by DRIP20 (https://github.com/0xBeans/DRIP20)
abstract contract ERC20DripUDS is ERC20UDS {
    /* ------------- public ------------- */

    function dripDailyRate() public view virtual returns (uint256);

    function dripStart() public view virtual returns (uint256);

    function balanceOf(address owner) public view virtual override returns (uint256) {
        return erc20DS().balanceOf[owner] + _virtualBalanceOf(owner);
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _claimVirtualBalance(msg.sender);
        _claimVirtualBalance(to);

        erc20DS().balanceOf[msg.sender] -= amount;

        unchecked {
            erc20DS().balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        _claimVirtualBalance(from);
        _claimVirtualBalance(to);

        uint256 allowed = erc20DS().allowance[from][msg.sender];

        if (allowed != type(uint256).max) erc20DS().allowance[from][msg.sender] = allowed - amount;

        erc20DS().balanceOf[from] -= amount;

        unchecked {
            erc20DS().balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /* ------------- internal ------------- */

    function _increaseMultiplier(address owner, uint216 quantity) internal {
        _claimVirtualBalance(owner);

        s().dripData[owner].multiplier += uint216(quantity);
    }

    function _decreaseMultiplier(address owner, uint216 quantity) internal {
        _claimVirtualBalance(owner);

        s().dripData[owner].multiplier -= uint216(quantity);
    }

    function _virtualBalanceOf(address owner) internal view virtual returns (uint256) {
        DripData storage dripData = s().dripData[owner];

        uint256 multiplier = dripData.multiplier;

        if (multiplier == 0) return 0;

        uint256 lastClaimed = dripData.lastClaimed;

        if (lastClaimed == 0) lastClaimed = dripStart();

        uint256 timeDelta = block.timestamp - lastClaimed;

        return (timeDelta * multiplier * dripDailyRate()) / 1 days;
    }

    function _claimVirtualBalance(address owner) internal virtual {
        uint256 amount = _virtualBalanceOf(owner);

        _mint(owner, amount);

        s().dripData[owner].lastClaimed = uint40(block.timestamp);
    }
}
