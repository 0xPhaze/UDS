// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

/// @dev diamond storage slot `keccak256("diamond.storage.pausable")`
bytes32 constant DIAMOND_STORAGE_PAUSABLE = 0x6c12717fc0c7e094d0863d3779f70ed6b10509e4c31b62218121f564c04c42d9;

function s() pure returns (PausableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_PAUSABLE;
    assembly {
        diamondStorage.slot := slot
    }
}

struct PausableDS {
    uint256 paused;
}

// ------------- errors

error Paused();
error AlreadyPaused();
error AlreadyUnpaused();

/// @title Puasable (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
contract PausableUDS {
    PausableDS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- internal ------------- */

    function _pause() internal {
        if (s().paused == 2) revert AlreadyPaused();

        s().paused = 2;
    }

    function _unpause() internal {
        if (s().paused != 2) revert AlreadyUnpaused();

        s().paused = 1;
    }

    /* ------------- modifier ------------- */

    modifier notPaused() {
        if (s().paused == 2) revert Paused();

        _;
    }
}
