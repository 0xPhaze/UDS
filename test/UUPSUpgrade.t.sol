// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "/proxy/ERC1967Proxy.sol";

// ---------------------------------------------------------------------
// Mock Logic
// ---------------------------------------------------------------------

error RevertOnInit();

contract MockUUPSUpgradeV1 is MockUUPSUpgrade {
    uint256 public data = 0x1337;
    uint256 public initializedCount;

    uint256 public constant version = 1;

    function init() public {
        ++initializedCount;
    }

    function fn() public pure returns (uint256) {
        return 1337;
    }

    function setData(uint256 newData) public {
        data = newData;
    }
}

contract MockUUPSUpgradeV2 is MockUUPSUpgrade {
    address public data = address(0x42);

    uint256 public constant version = 2;

    function fn() public pure returns (uint256) {
        return 6969;
    }

    function fn2() public pure returns (uint256) {
        return 3141;
    }

    function initReverts() public pure {
        revert RevertOnInit();
    }

    function initRevertsWithMessage(string memory message) public pure {
        require(false, message);
    }
}

contract LogicNonexistentUUID {}

contract LogicInvalidUUID {
    bytes32 public proxiableUUID = 0x0000000000000000000000000000000000000000000000000000000000001234;
}

// ---------------------------------------------------------------------
// UUPSUpgrade Tests
// ---------------------------------------------------------------------

contract TestUUPSUpgrade is Test {
    event Upgraded(address indexed implementation);

    MockUUPSUpgradeV1 logicV1;
    MockUUPSUpgradeV2 logicV2;
    address proxy;

    function deployProxyAndCall(address implementation, bytes memory initCalldata) internal virtual returns (address) {
        return address(new ERC1967Proxy(address(implementation), initCalldata));
    }

    function setUp() public virtual {
        logicV1 = new MockUUPSUpgradeV1();
        logicV2 = new MockUUPSUpgradeV2();

        proxy = deployProxyAndCall(address(logicV1), "");
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(logicV1.version(), 1);
        assertEq(logicV2.version(), 2);
        assertEq(MockUUPSUpgradeV1(proxy).version(), 1);

        assertEq(logicV1.fn(), 1337);
        assertEq(logicV2.fn(), 6969);
        assertEq(logicV2.fn2(), 3141);
        assertEq(MockUUPSUpgradeV1(proxy).fn(), 1337);

        assertEq(logicV1.data(), 0x1337);
        assertEq(logicV2.data(), address(0x42));

        assertEq(MockUUPSUpgradeV1(proxy).data(), 0);
        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 0);

        assertEq(UPGRADED_EVENT_SIG, keccak256("Upgraded(address)"));
        assertEq(ERC1967_PROXY_STORAGE_SLOT, bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    }

    /* ------------- deployProxyAndCall() ------------- */

    /// expect implementation to be stored correctly
    function test_deployProxyAndCall_implementation() public {
        proxy = deployProxyAndCall(address(logicV1), "");

        // make sure that implementation is not
        // located in sequential storage slot
        MockUUPSUpgrade(proxy).scrambleStorage(0, 100);

        assertEq(MockUUPSUpgrade(proxy).implementation(), address(logicV1));
        assertEq(vm.load(proxy, ERC1967_PROXY_STORAGE_SLOT), bytes32(uint256(uint160(address(logicV1)))));
    }

    /// expect Upgraded(address) to be emitted
    function test_deployProxyAndCall_emit() public {
        vm.expectEmit(true, false, false, false);

        emit Upgraded(address(logicV1));

        proxy = deployProxyAndCall(address(logicV1), "");
    }

    /// expect proxy to call `init` during deployment
    function test_deployProxyAndCall_init() public {
        proxy = deployProxyAndCall(address(logicV1), abi.encodePacked(MockUUPSUpgradeV1.init.selector));

        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 1);
    }

    /// call a nonexistent init function
    function test_deployProxyAndCall_fail_fallback() public {
        vm.expectRevert();

        proxy = deployProxyAndCall(address(logicV1), abi.encodePacked("abcd"));
    }

    /// deploy and upgrade to an invalid address (EOA)
    function test_deployProxyAndCall_fail_NotAContract(bytes memory initCalldata) public {
        vm.expectRevert(NotAContract.selector);

        proxy = deployProxyAndCall(address(0xb0b), initCalldata);
    }

    /// deploy and upgrade to contract with an invalid uuid
    function test_deployProxyAndCall_fail_InvalidUUID(bytes memory initCalldata) public {
        address logic2 = address(new LogicInvalidUUID());

        vm.expectRevert(InvalidUUID.selector);

        proxy = deployProxyAndCall(address(logic2), initCalldata);
    }

    /// deploy and upgrade to a contract that doesn't implement proxiableUUID
    /// this one reverts differently depending on proxy..
    function test_deployProxyAndCall_fail_NonexistentUUID(bytes memory initCalldata) public {
        address logic2 = address(new LogicNonexistentUUID());

        vm.expectRevert();

        proxy = deployProxyAndCall(address(logic2), initCalldata);
    }

    /// call a reverting init function
    function testFail_deployProxyAndCall_fail_RevertOnInit() public {
        // vm.expectRevert(RevertOnInit.selector);

        proxy = deployProxyAndCall(address(logicV2), abi.encodePacked(MockUUPSUpgradeV2.initReverts.selector));
    }

    /// call a reverting function during deployment
    /// make sure the error is returned
    function testFail_deployProxyAndCall_fail_initRevertsWithMessage(bytes memory message) public {
        // vm.expectRevert(message);

        bytes memory initCalldata = abi.encodeWithSelector(MockUUPSUpgradeV2.initRevertsWithMessage.selector, message);

        proxy = deployProxyAndCall(address(logicV1), initCalldata);
    }

    /* ------------- upgradeToAndCall() ------------- */

    /// expect implementation logic to change on upgrade
    function test_upgradeToAndCall_logic() public {
        assertEq(MockUUPSUpgradeV1(proxy).data(), 0);

        // proxy can call v1's setData
        MockUUPSUpgradeV1(proxy).setData(0x3333);

        assertEq(MockUUPSUpgradeV1(proxy).data(), 0x3333); // proxy's data now has changed
        assertEq(logicV1.data(), 0x1337); // implementation's data remains unchanged

        // -> upgrade to v2
        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(logicV2), "");

        // test v2 functions
        assertEq(MockUUPSUpgradeV2(proxy).fn(), 6969);
        assertEq(MockUUPSUpgradeV2(proxy).fn2(), 3141);

        // make sure data remains unchanged (though returned as address now)
        assertEq(MockUUPSUpgradeV2(proxy).data(), address(0x3333));

        // only available under v1 logic
        vm.expectRevert();
        MockUUPSUpgradeV1(proxy).setData(0x456);

        // <- upgrade back to v1
        MockUUPSUpgradeV2(proxy).upgradeToAndCall(address(logicV1), "");

        // v1's setData works again
        MockUUPSUpgradeV1(proxy).setData(0x6666);

        assertEq(MockUUPSUpgradeV1(proxy).data(), 0x6666);

        // only available under v2 logic
        vm.expectRevert();
        MockUUPSUpgradeV2(proxy).fn2();
    }

    /// expect implementation to be stored correctly
    function test_upgradeToAndCall_implementation() public {
        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(logicV2), "");

        MockUUPSUpgrade(proxy).scrambleStorage(0, 100);

        assertEq(MockUUPSUpgradeV1(proxy).implementation(), address(logicV2));
        assertEq(vm.load(proxy, ERC1967_PROXY_STORAGE_SLOT), bytes32(uint256(uint160(address(logicV2)))));
    }

    /// expect Upgraded(address) to be emitted
    function test_upgradeToAndCall_emit() public {
        vm.expectEmit(true, false, false, false, proxy);

        emit Upgraded(address(logicV2));

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(logicV2), "");

        vm.expectEmit(true, false, false, false, proxy);

        emit Upgraded(address(logicV1));

        MockUUPSUpgradeV2(proxy).upgradeToAndCall(address(logicV1), "");
    }

    /// expect upgradeToAndCall to actually call the function
    function test_upgradeToAndCall_init() public {
        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 0);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(logicV1), abi.encodePacked(MockUUPSUpgradeV1.init.selector));

        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 1);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(logicV1), abi.encodePacked(MockUUPSUpgradeV1.init.selector));

        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 2);
    }

    /// upgrade and call a nonexistent init function
    function test_upgradeToAndCall_fail_fallback() public {
        vm.expectRevert();

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(logicV2), "abcd");
    }

    /// upgrade to v2 and call a reverting init function
    /// expect revert reason to bubble up
    function test_upgradeToAndCall_fail_RevertOnInit() public {
        vm.expectRevert(RevertOnInit.selector);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(
            address(logicV2),
            abi.encodePacked(MockUUPSUpgradeV2.initReverts.selector)
        );
    }

    /// call a reverting function during upgrade
    /// make sure the error is returned
    function test_upgradeToAndCall_fail_initRevertsWithMessage(string memory message) public {
        vm.expectRevert(bytes(message));

        bytes memory initCalldata = abi.encodeWithSelector(MockUUPSUpgradeV2.initRevertsWithMessage.selector, message);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(logicV2), initCalldata);
    }

    /// upgrade to an invalid address (EOA)
    function test_upgradeToAndCall_fail_NotAContract(bytes memory initCalldata) public {
        vm.expectRevert(NotAContract.selector);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(address(0xb0b), initCalldata);
    }

    /// upgrade to contract with an invalid uuid
    function test_upgradeToAndCall_fail_InvalidUUID(bytes memory initCalldata) public {
        address logic = address(new LogicInvalidUUID());

        vm.expectRevert(InvalidUUID.selector);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logic, initCalldata);
    }

    /// upgrade to a contract that doesn't implement proxiableUUID
    function test_upgradeToAndCall_fail_NonexistentUUID(bytes memory initCalldata) public {
        address logic = address(new LogicNonexistentUUID());

        vm.expectRevert();

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logic, initCalldata);
    }
}
