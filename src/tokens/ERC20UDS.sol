// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializableUDS} from "../auth/InitializableUDS.sol";
import {EIP712PermitUDS} from "../auth/EIP712PermitUDS.sol";

// ------------- storage

// keccak256("diamond.storage.erc20") == 0x0e539be85842d1c3b5b43263a827c1e07ab5a9c9536bf840ece723e480d80db7;
bytes32 constant DIAMOND_STORAGE_ERC20 = 0x0e539be85842d1c3b5b43263a827c1e07ab5a9c9536bf840ece723e480d80db7;

function s() pure returns (ERC20DS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_ERC20 } // prettier-ignore
}

struct ERC20DS {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance;
}

/// @title ERC20 (Upgradeable Diamond Storage)
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
abstract contract ERC20UDS is InitializableUDS, EIP712PermitUDS {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /* ------------- init ------------- */

    function __ERC20_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initializer {
        s().name = _name;
        s().symbol = _symbol;
        s().decimals = _decimals;
    }

    /* ------------- view ------------- */

    function name() external view virtual returns (string memory) {
        return s().name;
    }

    function symbol() external view virtual returns (string memory) {
        return s().symbol;
    }

    function decimals() external view virtual returns (uint8) {
        return s().decimals;
    }

    function totalSupply() external view virtual returns (uint256) {
        return s().totalSupply;
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        return s().balanceOf[owner];
    }

    function allowance(address operator, address owner) public view virtual returns (uint256) {
        return s().allowance[operator][owner];
    }

    /* ------------- public ------------- */

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        s().allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        s().balanceOf[msg.sender] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = s().allowance[from][msg.sender];

        if (allowed != type(uint256).max) s().allowance[from][msg.sender] = allowed - amount;

        s().balanceOf[from] -= amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    // EIP-2612 permit
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public virtual {
        if (_usePermit(owner, spender, value, deadline, v, r, s_)) {
            s().allowance[owner][spender] = value;

            emit Approval(owner, spender, value);
        }
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 amount) internal virtual {
        s().totalSupply += amount;

        unchecked {
            s().balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        s().balanceOf[from] -= amount;

        unchecked {
            s().totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
