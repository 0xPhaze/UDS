// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {UUPSUpgradeV} from "../../proxy/UUPSUpgradeV.sol";
import "../../ERC721UDS.sol";

contract MockERC721UDS is UUPSUpgradeV(1), ERC721UDS {
    function init(string memory _name, string memory _symbol) external initializer {
        __ERC721UDS_init(_name, _symbol);
    }

    function _authorizeUpgrade() internal virtual override {}

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mint(address to, uint256 tokenId) public virtual {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    function safeMint(address to, uint256 tokenId) public virtual {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        _safeMint(to, tokenId, data);
    }
}
