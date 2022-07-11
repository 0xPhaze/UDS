// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UUPSUpgrade} from "../../proxy/UUPSUpgrade.sol";
import "../../ERC1155UDS.sol";

contract MockERC1155UDS is UUPSUpgrade, ERC1155UDS {
    function _authorizeUpgrade() internal virtual override {}

    function uri(uint256) public pure virtual override returns (string memory) {}

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        _mint(to, id, amount, data);
    }

    function batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        _batchMint(to, ids, amounts, data);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public virtual {
        _burn(from, id, amount);
    }

    function batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public virtual {
        _batchBurn(from, ids, amounts);
    }
}
