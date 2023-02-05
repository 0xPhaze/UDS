// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./mocks/MockERC721EnumerableUDS.sol";
import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MockERC721UDS, TestERC721UDS} from "./solmate/ERC721UDS.t.sol";

import "forge-std/Test.sol";
import {futils, random} from "futils/futils.sol";

contract TestERC721UDSEnumerableTestERC721UDS is TestERC721UDS {
    function setUp() public override {
        bytes memory initCalldata = abi.encodeWithSelector(MockERC721EnumerableUDS.init.selector, "Token", "TKN");

        logic = address(new MockERC721EnumerableUDS());
        token = MockERC721UDS(address(new ERC1967Proxy(logic, initCalldata)));
    }
}

contract TestERC721UDSEnumerable is Test {
    using futils for *;

    address alice = address(0xbabe);
    address bob = address(0xb0b);
    address eve = address(0xefe);
    address self = address(this);

    MockERC721EnumerableUDS token;
    address logic;

    function setUp() public {
        bytes memory initCalldata = abi.encodeWithSelector(MockERC721EnumerableUDS.init.selector, "Token", "TKN");

        logic = address(new MockERC721EnumerableUDS());
        token = MockERC721EnumerableUDS(address(new ERC1967Proxy(logic, initCalldata)));
    }

    function test_setUp() public {
        ERC721EnumerableDS storage diamondStorage = s();

        bytes32 slot;

        assembly {
            slot := diamondStorage.slot
        }

        assertEq(slot, keccak256("diamond.storage.erc721.enumerable"));
        assertEq(DIAMOND_STORAGE_ERC721_ENUMERABLE, keccak256("diamond.storage.erc721.enumerable"));
    }

    /* ------------- helper ------------- */

    function _mint(address user, uint256[] memory ids) public {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            token.mint(user, ids[i]);
        }
    }

    function _burn(uint256[] memory ids) public {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            token.burn(ids[i]);
        }
    }

    function _transferFrom(address from, address to, uint256[] memory ids) public {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            token.transferFrom(from, to, ids[i]);
        }
    }

    function assertIdsInGlobalEnumeration(uint256[] memory ids) internal {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            assertTrue(ids.includes(token.tokenByIndex(i)));
        }

        assertEq(token.totalSupply(), length);
        assertEq(token.getAllIds().sort(), ids.sort());
    }

    function assertIdsInUserEnumeration(address user, uint256[] memory ids) internal {
        uint256 length = ids.length;

        for (uint256 i; i < length; ++i) {
            assertTrue(ids.includes(token.tokenOfOwnerByIndex(user, i)));
            // assertTrue(token.userOwnsId(user, ids[i]));
        }

        assertEq(token.balanceOf(user), length);
        assertEq(token.getOwnedIds(user).sort(), ids.sort());
    }

    /* ------------- mint() ------------- */

    function test_mint() public {
        uint256[] memory idsSelf = 1.range(6);
        uint256[] memory idsAlice = 10.range(21);

        _mint(self, idsSelf);
        _mint(alice, idsAlice);

        assertIdsInUserEnumeration(self, idsSelf);
        assertIdsInUserEnumeration(alice, idsAlice);
        assertIdsInGlobalEnumeration(idsSelf.union(idsAlice));
    }

    /* ------------- burn() ------------- */

    function test_burn() public {
        uint256[] memory idsSelf = 1.range(6);
        uint256[] memory idsAlice = 10.range(21);

        _mint(self, idsSelf);
        _mint(alice, idsAlice);

        uint256[] memory idsSelfBurn = [3, 1].toMemory();
        uint256[] memory idsAliceBurn = [10, 15, 16].toMemory();

        _burn(idsSelfBurn);
        _burn(idsAliceBurn);

        assertIdsInUserEnumeration(self, idsSelf.exclude(idsSelfBurn));
        assertIdsInUserEnumeration(alice, idsAlice.exclude(idsAliceBurn));
        assertIdsInGlobalEnumeration(idsSelf.union(idsAlice).exclude(idsSelfBurn).exclude(idsAliceBurn));
    }

    /* ------------- transfer() ------------- */

    function test_transfer() public {
        uint256[] memory idsSelf = 1.range(6);
        uint256[] memory idsAlice = 10.range(21);

        uint256[] memory idsTransfer = [3, 1].toMemory();

        _mint(self, idsSelf);
        _mint(alice, idsAlice);

        _transferFrom(self, alice, idsTransfer);

        assertIdsInUserEnumeration(self, idsSelf.exclude(idsTransfer));
        assertIdsInUserEnumeration(alice, idsAlice.union(idsTransfer));
        assertIdsInGlobalEnumeration(idsSelf.union(idsAlice));
    }

    /* ------------- transfer() ------------- */

    function test_mint(uint256 quantityA, uint256 quantityB, uint256 quantityE) public {
        quantityA = bound(quantityA, 1, 100);
        quantityB = bound(quantityB, 1, 100);
        quantityE = bound(quantityE, 1, 100);

        uint256[] memory idsAlice = (1).range(1 + quantityA);
        uint256[] memory idsBob = (1 + quantityA).range(1 + quantityA + quantityB);
        uint256[] memory idsEve = (1 + quantityA + quantityB).range(1 + quantityA + quantityB + quantityE);
        uint256[] memory allIds = idsAlice.union(idsBob).union(idsEve);

        _mint(alice, idsAlice);
        _mint(bob, idsBob);
        _mint(eve, idsEve);

        assertIdsInUserEnumeration(alice, idsAlice);
        assertIdsInUserEnumeration(bob, idsBob);
        assertIdsInUserEnumeration(eve, idsEve);
        assertIdsInGlobalEnumeration(allIds);
    }

    function test_transferFrom(uint256 seed, address[] calldata nextOwners) public {
        random.seed(seed);

        uint256 n = 10;

        test_mint(n - 1, n - 1, n - 1);

        uint256 totalSupply = 3 * n;
        address[] memory owners = new address[](totalSupply);

        for (uint256 i; i < n; ++i) {
            owners[i] = alice;
        }
        for (uint256 i; i < n; ++i) {
            owners[n + i] = bob;
        }
        for (uint256 i; i < n; ++i) {
            owners[n + n + i] = eve;
        }

        for (uint256 i; i < nextOwners.length; ++i) {
            uint256 id = random.next(totalSupply);
            address oldOwner = owners[id];
            address newOwner = nextOwners[i];

            if (newOwner == address(0)) continue;

            vm.prank(oldOwner);
            token.transferFrom(oldOwner, newOwner, 1 + id);

            owners[id] = newOwner;

            uint256[] memory newOwnerIds = owners.filterIndices(newOwner);
            for (uint256 j; j < newOwnerIds.length; j++) {
                ++newOwnerIds[j];
            }

            assertEq(token.getOwnedIds(newOwner).sort(), newOwnerIds.sort());
        }
    }
}
