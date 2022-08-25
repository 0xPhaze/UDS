// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS, s as erc721ds} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {Initializable} from "UDS/utils/Initializable.sol";

contract MyNFTUpgradeableV1 is UUPSUpgrade, Initializable, OwnableUDS, ERC721UDS {
    string public baseURI = "URI";

    function init() public initializer {
        __Ownable_init();
        __ERC721_init("Non-fungible Contract", "NFT");
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}

contract MyNFTUpgradeableV2 is UUPSUpgrade, Initializable, OwnableUDS, ERC721UDS {
    string public baseURI;
    string public constant override name = "Non-fungible Contract V2";
    string public constant override symbol = "NFTV2";

    function init() public reinitializer {
        baseURI = "URIV2";
        _mint(msg.sender, 1);
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}
