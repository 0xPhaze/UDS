// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";

// ------------- storage

// keccak256("diamond.storage.access.control") == 0xd229c8df724bc36c62cde04d6d208a43a60480edccfde27ef78f260014374ebd
bytes32 constant DIAMOND_STORAGE_ACCESS_CONTROL = 0xd229c8df724bc36c62cde04d6d208a43a60480edccfde27ef78f260014374ebd;

struct RoleData {
    bytes32 adminRole;
    mapping(address => bool) members;
}

struct AccessControlDS {
    mapping(bytes32 => RoleData) roles;
}

function s() pure returns (AccessControlDS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ACCESS_CONTROL } // prettier-ignore
}

// ------------- errors

error NotAuthorized();
error RenounceForCallerOnly();

/// @notice AccessControl compatible with diamond storage
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/)
abstract contract AccessControlUDS is InitializableUDS {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /* ------------- init ------------- */

    function __AccessControl_init() external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ------------- view ------------- */

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x7965db0b; // ERC165 Interface ID for AccessControl
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

    function renounceRole(bytes32 role) public virtual {
        _revokeRole(role, msg.sender);
    }

    /* ------------- internal ------------- */

    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            s().roles[role].members[account] = true;

            emit RoleGranted(role, account, msg.sender);
        }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            s().roles[role].members[account] = false;

            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);

        s().roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /* ------------- modifier ------------- */

    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, msg.sender)) revert NotAuthorized();
        _;
    }
}
