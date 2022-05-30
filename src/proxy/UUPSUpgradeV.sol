// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC1822Versioned, ERC1822Versioned} from "./ERC1822Versioned.sol";
import {ERC1967Versioned, DIAMOND_STORAGE_ERC1967_UPGRADE} from "./ERC1967VersionedUDS.sol";

/* ------------- Storage ------------- */

// keccak256("diamond.storage.uups.versioned.upgrade") == 0x84baf5225d2c25e851ba08f5463fbda2857188d63388c0dc9b62907467b54b47;
bytes32 constant DIAMOND_STORAGE_UUPS_VERSIONED_UPGRADE = 0x84baf5225d2c25e851ba08f5463fbda2857188d63388c0dc9b62907467b54b47;

struct UUPSUpgradeVDS {
    uint256 version;
}

function ds() pure returns (UUPSUpgradeVDS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_UUPS_VERSIONED_UPGRADE
    }
}

/* ------------- Errors ------------- */

error OnlyProxyCallAllowed();
error DelegateCallNotAllowed();

/* ------------- UUPSUpgradeV ------------- */

abstract contract UUPSUpgradeV is ERC1967Versioned, ERC1822Versioned {
    address private immutable __implementation = address(this);
    uint256 private immutable __version;

    constructor(uint256 version) {
        __version = version;
    }

    function proxiableVersion() public view override returns (uint256) {
        return __version;
    }

    /* ------------- External ------------- */

    function upgradeTo(address logic) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, "");
    }

    function upgradeToAndCall(address logic, bytes calldata data) external payable {
        _authorizeUpgrade();
        _upgradeToAndCall(logic, data);
    }

    /* ------------- View ------------- */

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return DIAMOND_STORAGE_ERC1967_UPGRADE;
    }

    /* ------------- Virtual ------------- */

    function _authorizeUpgrade() internal virtual;

    /* ------------- Modifier ------------- */

    modifier onlyProxy() {
        if (address(this) == __implementation) revert OnlyProxyCallAllowed();
        _;
    }

    modifier notDelegated() {
        if (address(this) != __implementation) revert DelegateCallNotAllowed();
        _;
    }
}
