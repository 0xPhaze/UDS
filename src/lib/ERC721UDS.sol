// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";
import {EIP712PermitUDS} from "./EIP712PermitUDS.sol";

/* ------------- Storage ------------- */

struct ERC721DS {
    string name;
    string symbol;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) getApproved;
    mapping(address => mapping(address => bool)) isApprovedForAll;
}

// keccak256("diamond.storage.erc721") == 0xf2dec0acaef95de6625646379d631adff4db9f6c79b84a31adcb9a23bf6cea78;
bytes32 constant DIAMOND_STORAGE_ERC721 = 0xf2dec0acaef95de6625646379d631adff4db9f6c79b84a31adcb9a23bf6cea78;

function ds() pure returns (ERC721DS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_ERC721
    }
}

/* ------------- Errors ------------- */

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

/* ------------- ERC721UDS ------------- */

/// @notice Adapted for usage with Diamond Storage
/// @author phaze (https://github.com/0xPhaze)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721UDS is InitializableUDS, EIP712PermitUDS {
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /* ------------- Init ------------- */

    function __ERC721UDS_init(string memory name_, string memory symbol_) internal initializer {
        ds().name = name_;
        ds().symbol = symbol_;
    }

    /* ------------- View ------------- */

    function tokenURI(uint256 id) public view virtual returns (string memory);

    function name() external view returns (string memory) {
        return ds().name;
    }

    function symbol() external view returns (string memory) {
        return ds().symbol;
    }

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = ds().owners[id]) == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert BalanceOfZeroAddress();

        return ds().balances[owner];
    }

    function getApproved(uint256 id) public view returns (address) {
        return ds().getApproved[id];
    }

    function isApprovedForAll(address operator, address owner) public view returns (bool) {
        return ds().isApprovedForAll[operator][owner];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /* ------------- Public ------------- */

    function approve(address spender, uint256 id) public virtual {
        address owner = ds().owners[id];

        if (msg.sender != owner && !ds().isApprovedForAll[owner][msg.sender]) revert CallerNotOwnerNorApproved();

        ds().getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        ds().isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        if (to == address(0)) revert TransferToZeroAddress();
        if (from != ds().owners[id]) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (msg.sender == from ||
            ds().isApprovedForAll[from][msg.sender] ||
            ds().getApproved[id] == msg.sender);

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        unchecked {
            ds().balances[from]--;
            ds().balances[to]++;
        }

        ds().owners[id] = to;

        delete ds().getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    // EIP-4494 permit; differs from the current EIP
    function permit(
        address owner,
        address operator,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (_usePermit(owner, operator, 1, deadline, v, r, s)) {
            ds().isApprovedForAll[owner][operator] = true;
            emit ApprovalForAll(owner, operator, true);
        }
    }

    /* ------------- Internal ------------- */

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert MintToZeroAddress();
        if (ds().owners[id] != address(0)) revert MintExistingToken();

        unchecked {
            ds().balances[to]++;
        }

        ds().owners[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ds().owners[id];

        if (owner == address(0)) revert NonexistentToken();

        unchecked {
            ds().balances[owner]--;
        }

        delete ds().owners[id];
        delete ds().getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (
            to.code.length != 0 &&
            ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) !=
            ERC721TokenReceiver.onERC721Received.selector
        ) revert NonERC721Receiver();
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
