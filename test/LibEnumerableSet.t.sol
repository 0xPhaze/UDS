// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "UDS/lib/LibEnumerableSet.sol";

contract TestEnumerableUint256Set is Test {
    using LibEnumerableSet for LibEnumerableSet.Uint256Set;

    LibEnumerableSet.Uint256Set set;
    uint256[] _setValues;

    /* ------------- O(n) helpers ------------- */

    function indexOfValue(uint256 value) internal view returns (uint256) {
        for (uint256 i; i < _setValues.length; i++) if (_setValues[i] == value) return i;
        return type(uint256).max;
    }

    function valuesInclude(uint256 value) internal view returns (bool) {
        return indexOfValue(value) != type(uint256).max;
    }

    function assertEq(LibEnumerableSet.Uint256Set storage set_, uint256[] storage values) internal {
        assertEq(set_.length(), values.length);

        for (uint256 i; i < values.length; i++) {
            assertTrue(set_.includes(values[i]));
        }
    }

    function assertIsUniqueSet(LibEnumerableSet.Uint256Set storage set_) internal {
        uint256[] memory values = set_.values();
        for (uint256 i; i < values.length; i++) {
            for (uint256 j = i + 1; j < values.length; j++) {
                assertTrue(values[i] != values[j]);
            }
        }
    }

    /* ------------- add() ------------- */

    function test_add(uint256 value) public {
        bool includes = set.includes(value);
        bool added = set.add(value);

        assertEq(added, !includes);
        assertTrue(set.includes(value));
        assertEq(set.at(set._indices[value] - 1), value);

        // mirror by performing "dumb" O(n) operations

        assertEq(includes, valuesInclude(value));

        if (!includes) _setValues.push(value);

        assertTrue(valuesInclude(value));
        assertIsUniqueSet(set);
    }

    /* ------------- remove() ------------- */

    function test_rem(uint256 value) public {
        bool includes = set.includes(value);
        bool removed = set.remove(value);

        assertEq(removed, includes);
        assertFalse(set.includes(value));

        // mirror

        assertEq(includes, valuesInclude(value));

        if (includes) {
            _setValues[indexOfValue(value)] = _setValues[_setValues.length - 1];
            _setValues.pop();
        }

        assertFalse(valuesInclude(value));
        assertIsUniqueSet(set);
    }

    /* ------------- add_remove() ------------- */

    function test_add_remove() public {
        test_rem(3);
        test_add(1);
        test_add(2);
        test_add(3);
        test_rem(3);
        test_add(2);
        test_rem(4);
        test_add(2);
        test_rem(3);
        test_add(2);
        test_rem(1);
        test_add(5);
        test_rem(1);
        test_add(5);
        test_add(7);
        test_rem(8);
        test_rem(2);
        test_rem(9);
        test_rem(3);

        assertEq(set, _setValues);
    }

    function test_add_remove(uint8[] calldata values) public {
        for (uint256 i; i < values.length; i++) {
            uint256 value = values[i];
            if (value > 100) test_add(value % 100);
            else test_rem(value % 100);
        }

        assertEq(set, _setValues);
    }
}

contract TestEnumerableBytes32Set is Test {
    using LibEnumerableSet for LibEnumerableSet.Bytes32Set;

    LibEnumerableSet.Bytes32Set set;
    bytes32[] _setValues;

    /* ------------- O(n) helpers ------------- */

    function indexOfValue(bytes32 value) internal view returns (uint256) {
        for (uint256 i; i < _setValues.length; i++) if (_setValues[i] == value) return i;
        return type(uint256).max;
    }

    function valuesInclude(bytes32 value) internal view returns (bool) {
        return indexOfValue(value) != type(uint256).max;
    }

    function assertEq(LibEnumerableSet.Bytes32Set storage set_, bytes32[] storage values) internal {
        assertEq(set_.length(), values.length);

        for (uint256 i; i < values.length; i++) {
            assertTrue(set_.includes(values[i]));
        }
    }

    function assertIsUniqueSet(LibEnumerableSet.Bytes32Set storage set_) internal {
        bytes32[] memory values = set_.values();
        for (uint256 i; i < values.length; i++) {
            for (uint256 j = i + 1; j < values.length; j++) {
                assertTrue(values[i] != values[j]);
            }
        }
    }

    /* ------------- add() ------------- */

    function test_add(bytes32 value) public {
        bool includes = set.includes(value);
        bool added = set.add(value);

        assertEq(added, !includes);
        assertTrue(set.includes(value));
        assertEq(set.at(set._indices[value] - 1), value);

        // mirror by performing "dumb" O(n) operations

        assertEq(includes, valuesInclude(value));

        if (!includes) _setValues.push(value);

        assertTrue(valuesInclude(value));
        assertIsUniqueSet(set);
    }

    /* ------------- remove() ------------- */

    function test_rem(bytes32 value) public {
        bool includes = set.includes(value);
        bool removed = set.remove(value);

        assertEq(removed, includes);
        assertFalse(set.includes(value));

        // mirror

        assertEq(includes, valuesInclude(value));

        if (includes) {
            _setValues[indexOfValue(value)] = _setValues[_setValues.length - 1];
            _setValues.pop();
        }

        assertFalse(valuesInclude(value));
        assertIsUniqueSet(set);
    }

    /* ------------- add_remove() ------------- */

    function test_add_remove() public {
        test_rem(bytes32(uint256(3)));
        test_add(bytes32(uint256(1)));
        test_add(bytes32(uint256(2)));
        test_add(bytes32(uint256(3)));
        test_rem(bytes32(uint256(3)));
        test_add(bytes32(uint256(2)));
        test_rem(bytes32(uint256(4)));
        test_add(bytes32(uint256(2)));
        test_rem(bytes32(uint256(3)));
        test_add(bytes32(uint256(2)));
        test_rem(bytes32(uint256(1)));
        test_add(bytes32(uint256(5)));
        test_rem(bytes32(uint256(1)));
        test_add(bytes32(uint256(5)));
        test_add(bytes32(uint256(7)));
        test_rem(bytes32(uint256(8)));
        test_rem(bytes32(uint256(2)));
        test_rem(bytes32(uint256(9)));
        test_rem(bytes32(uint256(3)));

        assertEq(set, _setValues);
    }

    function test_add_remove(uint8[] calldata values) public {
        for (uint256 i; i < values.length; i++) {
            uint256 value = values[i];
            if (value > 100) test_add(bytes32(value % 100));
            else test_rem(bytes32(value % 100));
        }

        assertEq(set, _setValues);
    }
}

contract TestEnumerableAddressSet is Test {
    using LibEnumerableSet for LibEnumerableSet.AddressSet;

    LibEnumerableSet.AddressSet set;
    address[] _setValues;

    /* ------------- O(n) helpers ------------- */

    function indexOfValue(address value) internal view returns (uint256) {
        for (uint256 i; i < _setValues.length; i++) if (_setValues[i] == value) return i;
        return type(uint256).max;
    }

    function valuesInclude(address value) internal view returns (bool) {
        return indexOfValue(value) != type(uint256).max;
    }

    function assertEq(LibEnumerableSet.AddressSet storage set_, address[] storage values) internal {
        assertEq(set_.length(), values.length);

        for (uint256 i; i < values.length; i++) {
            assertTrue(set_.includes(values[i]));
        }
    }

    function assertIsUniqueSet(LibEnumerableSet.AddressSet storage set_) internal {
        address[] memory values = set_.values();
        for (uint256 i; i < values.length; i++) {
            for (uint256 j = i + 1; j < values.length; j++) {
                assertTrue(values[i] != values[j]);
            }
        }
    }

    /* ------------- add() ------------- */

    function test_add(address value) public {
        bool includes = set.includes(value);
        bool added = set.add(value);

        assertEq(added, !includes);
        assertTrue(set.includes(value));
        assertEq(set.at(set._indices[value] - 1), value);

        // mirror by performing "dumb" O(n) operations

        assertEq(includes, valuesInclude(value));

        if (!includes) _setValues.push(value);

        assertTrue(valuesInclude(value));
        assertIsUniqueSet(set);
    }

    /* ------------- remove() ------------- */

    function test_rem(address value) public {
        bool includes = set.includes(value);
        bool removed = set.remove(value);

        assertEq(removed, includes);
        assertFalse(set.includes(value));

        // mirror

        assertEq(includes, valuesInclude(value));

        if (includes) {
            _setValues[indexOfValue(value)] = _setValues[_setValues.length - 1];
            _setValues.pop();
        }

        assertFalse(valuesInclude(value));
        assertIsUniqueSet(set);
    }

    /* ------------- add_remove() ------------- */

    function test_add_remove() public {
        test_rem(address(3));
        test_add(address(1));
        test_add(address(2));
        test_add(address(3));
        test_rem(address(3));
        test_add(address(2));
        test_rem(address(4));
        test_add(address(2));
        test_rem(address(3));
        test_add(address(2));
        test_rem(address(1));
        test_add(address(5));
        test_rem(address(1));
        test_add(address(5));
        test_add(address(7));
        test_rem(address(8));
        test_rem(address(2));
        test_rem(address(9));
        test_rem(address(3));

        assertEq(set, _setValues);
    }

    function test_add_remove(uint8[] calldata values) public {
        for (uint256 i; i < values.length; i++) {
            uint256 value = values[i];
            if (value > 100) test_add(address(uint160(value % 100)));
            else test_rem(address(uint160(value % 100)));
        }

        assertEq(set, _setValues);
    }
}
