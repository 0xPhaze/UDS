// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";

// ------------- Storage

// keccak256("diamond.storage.ownable") == 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;
bytes32 constant DIAMOND_STORAGE_OWNABLE = 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;

function s() pure returns (OwnableDS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_OWNABLE } // prettier-ignore
}

struct OwnableDS {
    address owner;
}

// ------------- Errors

error CallerNotOwner();
error CallerNotNominated();

/// @notice Ownable compatible with diamond storage
/// @notice Uses deployer as fallback if not initialized
/// @author phaze (https://github.com/0xPhaze/UDS)
abstract contract OwnableUDS is InitializableUDS {
    event OwnerChanged(address oldOwner, address newOwner);

    address private immutable fallbackOwner = msg.sender;

    function __Ownable_init() internal initializer {
        s().owner = msg.sender;
    }

    /* ------------- External ------------- */

    function owner() public view returns (address) {
        address _owner = s().owner;

        return _owner != address(0) ? _owner : fallbackOwner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        s().owner = newOwner;

        emit OwnerChanged(msg.sender, newOwner);
    }

    /* ------------- Modifier ------------- */

    modifier onlyOwner() {
        if (msg.sender != owner()) revert CallerNotOwner();
        _;
    }
}
