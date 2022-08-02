// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("diamond.storage.reentrancy.guard") == 0xded7818ea165bb3b944d9c6669a17f73a83aecd88f6983ef92ba87bdc26813fa;
bytes32 constant DIAMOND_STORAGE_REENTRANCY_GUARD = 0xded7818ea165bb3b944d9c6669a17f73a83aecd88f6983ef92ba87bdc26813fa;

function s() pure returns (ReentrancyGuardDS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_REENTRANCY_GUARD } // prettier-ignore
}

struct ReentrancyGuardDS {
    uint256 locked;
}

// ------------- errors

error ReentrancyNotPermitted();

/// @title Reentrancy Guard (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
contract ReentrancyGuardUDS {
    /* ------------- modifier ------------- */

    modifier nonReentrant() {
        if (s().locked == 2) revert ReentrancyNotPermitted();

        s().locked = 2;

        _;

        s().locked = 1;
    }
}
