// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, stdError} from "forge-std/Test.sol";

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockERC721EnumerableUDS} from "./mocks/MockERC721EnumerableUDS.sol";
import {TestERC721, MockERC721UDS} from "./solmate/ERC721UDS.t.sol";

import "UDS/tokens/extensions/ERC721EnumerableUDS.sol";

// TODO
// contract TestERC721Enumerable is Test {}

// all solmate ERC721 tests should pass
contract TestERC721EnumerableUDS is TestERC721 {
    function setUp() public override {
        logic = address(new MockERC721EnumerableUDS());

        bytes memory initCalldata = abi.encodeWithSelector(MockERC721EnumerableUDS.init.selector, "Token", "TKN", 18);
        token = MockERC721UDS(address(new ERC1967Proxy(logic, initCalldata)));
    }
}
