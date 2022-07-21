// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS} from "/tokens/ERC721UDS.sol";
import {OwnableUDS} from "/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "/proxy/UUPSUpgrade.sol";
import {InitializableUDS} from "/auth/InitializableUDS.sol";

contract MyNFTUpgradeableV1 is UUPSUpgrade, InitializableUDS, OwnableUDS, ERC721UDS {
    function init() public initializer {
        __Ownable_init();
        __ERC721_init("My NFT V1", "NFT V1");
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "URI";
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}

contract MyNFTUpgradeableV2 is UUPSUpgrade, InitializableUDS, OwnableUDS, ERC721UDS {
    function init() public initializer {
        __Ownable_init();
        __ERC721_init("My NFT V2", "NFT V2");
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "URI";
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}
