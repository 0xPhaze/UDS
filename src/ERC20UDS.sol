// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";
import {EIP712PermitUDS} from "./EIP712PermitUDS.sol";

/* ============= Storage ============= */

struct ERC20DS {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowance;
}

// keccak256("diamond.storage.erc20") == 0x0e539be85842d1c3b5b43263a827c1e07ab5a9c9536bf840ece723e480d80db7;
bytes32 constant DIAMOND_STORAGE_ERC20 = 0x0e539be85842d1c3b5b43263a827c1e07ab5a9c9536bf840ece723e480d80db7;

function s() pure returns (ERC20DS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_ERC20
    }
}

/* ============= Errors ============= */

error CallerNotOwnerNorApproved();
error NonexistentToken();
error NonERC721Receiver();

error BalanceOfZeroAddress();

error MintExistingToken();
error MintToZeroAddress();
error MintZeroQuantity();
error MintExceedsMaxSupply();
error MintExceedsMaxPerWallet();

error TransferFromIncorrectOwner();
error TransferToZeroAddress();

/* ============= ERC20UDS ============= */

/// @notice Adapted for usage with Diamond Storage
/// @author phaze (https://github.com/0xPhaze)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
abstract contract ERC20UDS is InitializableUDS, EIP712PermitUDS {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /* ------------- Init ------------- */

    function __ERC20UDS_init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal initializer {
        s().name = _name;
        s().symbol = _symbol;
        s().decimals = _decimals;
    }

    /* ------------- View ------------- */

    function name() external view returns (string memory) {
        return s().name;
    }

    function symbol() external view returns (string memory) {
        return s().symbol;
    }

    function decimals() external view returns (uint8) {
        return s().decimals;
    }

    function totalSupply() external view returns (uint256) {
        return s().totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return s().balances[owner];
    }

    function allowance(address operator, address owner) public view returns (uint256) {
        return s().allowance[operator][owner];
    }

    /* ------------- Public ------------- */

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        s().allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        s().balances[msg.sender] -= amount;

        unchecked {
            s().balances[to] += amount;
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

        s().balances[from] -= amount;

        unchecked {
            s().balances[to] += amount;
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

    /* ------------- Internal ------------- */

    function _mint(address to, uint256 amount) internal virtual {
        s().totalSupply += amount;

        unchecked {
            s().balances[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        s().balances[from] -= amount;

        unchecked {
            s().totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
