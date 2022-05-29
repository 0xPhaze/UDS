// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";

/* ------------- Storage ------------- */

// keccak256("diamond.storage.ownable") == 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;
bytes32 constant DIAMOND_STORAGE_OWNABLE = 0x87917b04fc43108fc3d291ac961b425fe1ddcf80087b2cb7e3c48f3e9233ea33;

struct OwnableDS {
    address owner;
}

function ds() pure returns (OwnableDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_OWNABLE
    }
}

/* ------------- Errors ------------- */

error CallerNotOwner();

/* ------------- Contract ------------- */

abstract contract OwnableUDS is InitializableUDS {
    address private immutable deployer;

    constructor() {
        deployer = msg.sender; // fallback owner
    }

    function __Ownable_init() internal initializer {
        ds().owner = msg.sender;
    }

    function owner() public view returns (address) {
        address _owner = ds().owner;
        return _owner != address(0) ? _owner : deployer;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        ds().owner = newOwner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner()) revert CallerNotOwner();
        _;
    }
}
