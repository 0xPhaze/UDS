// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {Initializable} from "UDS/auth/Initializable.sol";

contract MyNFTUpgradeableV1 is UUPSUpgrade, Initializable, OwnableUDS, ERC721UDS {
    function init() public initializer {
        __Ownable_init();
        __ERC721_init("Non-fungible Contract", "NFT");
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "URI";
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}

contract MyNFTUpgradeableV2 is UUPSUpgrade, Initializable, OwnableUDS, ERC721UDS {
    function init() public initializer {
        __Ownable_init();
        __ERC721_init("Non-fungible Contract V2", "NFTV2");
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "URI";
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}
