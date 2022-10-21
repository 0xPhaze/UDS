// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS} from "../ERC721UDS.sol";
import {LibEnumerableSet} from "UDS/lib/LibEnumerableSet.sol";

// ------------- storage

bytes32 constant DIAMOND_STORAGE_ERC721_ENUMERABLE = keccak256("diamond.storage.erc721.enumerable");

function s() pure returns (ERC721EnumerableDS storage diamondStorage) {
    bytes32 slot = DIAMOND_STORAGE_ERC721_ENUMERABLE;
    assembly { diamondStorage.slot := slot } // prettier-ignore
}

// Avoiding `LibEnumerableSet.Uint256Set` to save one sstore
struct IdsSet {
    mapping(uint256 => uint256) _values;
    mapping(uint256 => uint256) _indices;
}

struct ERC721EnumerableDS {
    mapping(uint256 => LibEnumerableSet.Uint256Set) allIds;
    mapping(address => IdsSet) ownedIds;
}

abstract contract ERC721EnumerableUDS is ERC721UDS {
    using LibEnumerableSet for LibEnumerableSet.Uint256Set;

    /* ------------- virtual ------------- */

    function tokenURI(uint256 id) public view virtual override returns (string memory);

    /* ------------- view ------------- */

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == 0x780e9d63 || // ERC165 Interface ID for ERC721Enumerable
            ERC721UDS.supportsInterface(interfaceId);
    }

    function totalSupply() public view virtual returns (uint256) {
        return s().allIds[0].length();
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        return s().allIds[0].at(index);
    }

    function getAllIds() public view virtual returns (uint256[] memory) {
        return s().allIds[0].values();
    }

    function tokenOfOwnerByIndex(address user, uint256 index) public view virtual returns (uint256) {
        return s().ownedIds[user]._values[index];
    }

    function getOwnedIds(address user) public view virtual returns (uint256[] memory ids) {
        uint256 len = ERC721UDS.balanceOf(user);

        ids = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            ids[i] = s().ownedIds[user]._values[i];
        }
    }

    /* ------------- private ------------- */

    function _addTokenToUserEnumeration(address user, uint256 id) private {
        IdsSet storage userIds = s().ownedIds[user];

        uint256 nextIndex = ERC721UDS.balanceOf(user);

        userIds._values[nextIndex] = id;
        userIds._indices[id] = nextIndex;
    }

    function _removeTokenOfUserEnumeration(address user, uint256 id) private {
        unchecked {
            IdsSet storage userIds = s().ownedIds[user];

            uint256 indexToReplace = userIds._indices[id];
            uint256 lastIndex = ERC721UDS.balanceOf(user) - 1;

            if (indexToReplace != lastIndex) {
                uint256 lastValue = userIds._values[lastIndex];

                userIds._values[indexToReplace] = lastValue;
                userIds._indices[lastValue] = indexToReplace;
            }

            delete userIds._indices[id];
            delete userIds._values[lastIndex];
        }
    }

    /* ------------- override ------------- */

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        if (from != to) {
            _removeTokenOfUserEnumeration(from, id);
            _addTokenToUserEnumeration(to, id);
        }

        ERC721UDS.transferFrom(from, to, id);
    }

    function _mint(address to, uint256 id) internal virtual override {
        _addTokenToUserEnumeration(to, id);

        s().allIds[0].add(id);

        ERC721UDS._mint(to, id);
    }

    function _burn(uint256 id) internal virtual override {
        _removeTokenOfUserEnumeration(ownerOf(id), id);

        s().allIds[0].remove(id);

        ERC721UDS._burn(id);
    }
}
