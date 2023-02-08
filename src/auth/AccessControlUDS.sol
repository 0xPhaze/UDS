// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "../utils/Initializable.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ACCESS_CONTROL = keccak256("diamond.storage.access.control");

function s() pure returns (AccessControlDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ACCESS_CONTROL;
    assembly {
        diamondStorage.slot := slot
    }
}

struct AccessControlDS {
    mapping(bytes32 => RoleData) roles;
}

struct RoleData {
    bytes32 adminRole;
    mapping(address => bool) members;
}

// ------------- errors

error NotAuthorized();
error RenounceForCallerOnly();

/// @title AccessControl (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts)
/// @dev Requires `__AccessControl_init` to be called in proxy
abstract contract AccessControlUDS is Initializable {
    AccessControlDS private __storageLayout; // storage layout for upgrade compatibility checks

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /* ------------- init ------------- */

    function __AccessControl_init() internal initializer {
        s().roles[DEFAULT_ADMIN_ROLE].members[msg.sender] = true;

        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);
    }

    /* ------------- view ------------- */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x7965db0b; // ERC165 Interface ID for AccessControl
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return s().roles[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return s().roles[role].adminRole;
    }

    /* ------------- public ------------- */

    function grantRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), msg.sender)) revert NotAuthorized();

        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual {
        if (!hasRole(getRoleAdmin(role), msg.sender)) revert NotAuthorized();

        _revokeRole(role, account);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);

        if (!hasRole(previousAdminRole, msg.sender)) revert NotAuthorized();

        _setRoleAdmin(role, adminRole);
    }

    function renounceRole(bytes32 role) public virtual {
        s().roles[role].members[msg.sender] = false;

        emit RoleRevoked(role, msg.sender, msg.sender);
    }

    /* ------------- internal ------------- */

    function _grantRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = true;

        emit RoleGranted(role, account, msg.sender);
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        s().roles[role].members[account] = false;

        emit RoleRevoked(role, account, msg.sender);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        s().roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    }

    /* ------------- modifier ------------- */

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert NotAuthorized();
        _;
    }
}
