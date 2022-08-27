// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS, s as erc721ds} from "../ERC721UDS.sol";
import {LibEnumerableSet, Uint256Set} from "../../lib/LibEnumerableSet.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC721_ENUMERABLE = keccak256("diamond.storage.erc721.enumerable");

function s() pure returns (ERC721EnumerableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC721_ENUMERABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

struct ERC721EnumerableDS {
    mapping(address => Uint256Set) ownedIds;
}

// ------------- errors

error NonexistentToken();
error NonERC721Receiver();
error MintExistingToken();
error MintToZeroAddress();
error BalanceOfZeroAddress();
error TransferToZeroAddress();
error CallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();

abstract contract ERC721EnumerableUDS is ERC721UDS {
    using LibEnumerableSet for Uint256Set;

    ERC721EnumerableDS private __storageLayout; // storage layout for upgrade compatibility checks

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) public view virtual override returns (string memory);

    /* ------------- view ------------- */

    function getOwnedIds(address owner) public view virtual returns (uint256[] memory) {
        return s().ownedIds[owner].values();
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceOfZeroAddress();

        return s().ownedIds[owner].length();
    }

    /* ------------- public ------------- */

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (to == address(0)) revert TransferToZeroAddress();
        if (from != erc721ds().ownerOf[id]) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            erc721ds().isApprovedForAll[from][_msgSender()] ||
            erc721ds().getApproved[id] == _msgSender());

        if (!isApprovedOrOwner) revert CallerNotOwnerNorApproved();

        erc721ds().ownerOf[id] = to;

        s().ownedIds[to].add(id);
        s().ownedIds[from].remove(id);

        delete erc721ds().getApproved[id];

        emit Transfer(from, to, id);
    }

    /* ------------- internal ------------- */

    function _mint(address to, uint256 id) internal virtual override {
        if (to == address(0)) revert MintToZeroAddress();
        if (erc721ds().ownerOf[id] != address(0)) revert MintExistingToken();

        erc721ds().ownerOf[id] = to;

        s().ownedIds[to].add(id);

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual override {
        address owner = erc721ds().ownerOf[id];

        if (owner == address(0)) revert NonexistentToken();

        delete erc721ds().ownerOf[id];
        delete erc721ds().getApproved[id];

        s().ownedIds[owner].remove(id);

        emit Transfer(owner, address(0), id);
    }
}
