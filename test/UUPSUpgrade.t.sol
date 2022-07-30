// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "UDS/proxy/ERC1967Proxy.sol";

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

contract TestUUPSUpgrade is Test {
    event Upgraded(address indexed implementation);

    address logicV1;
    address logicV2;
    address proxy;

    function deployProxyAndCall(address implementation, bytes memory initCalldata) internal virtual returns (address) {
        return address(new ERC1967Proxy(address(implementation), initCalldata));
    }

    function setUp() public virtual {
        logicV1 = address(new MockUUPSUpgradeV1());
        logicV2 = address(new MockUUPSUpgradeV2());

        proxy = deployProxyAndCall(logicV1, "");
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(MockUUPSUpgradeV1(logicV1).version(), 1);
        assertEq(MockUUPSUpgradeV2(logicV2).version(), 2);
        assertEq(MockUUPSUpgradeV1(proxy).version(), 1);

        assertEq(MockUUPSUpgradeV1(logicV1).fn(), 1337);
        assertEq(MockUUPSUpgradeV2(logicV2).fn(), 6969);
        assertEq(MockUUPSUpgradeV2(logicV2).fn2(), 3141);
        assertEq(MockUUPSUpgradeV1(proxy).fn(), 1337);

        assertEq(MockUUPSUpgradeV1(logicV1).data(), 0x1337);
        assertEq(MockUUPSUpgradeV2(logicV2).data(), address(0x42));

        assertEq(MockUUPSUpgradeV1(proxy).data(), 0);
        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 0);

        MockUUPSUpgrade(proxy).scrambleStorage(0, 100);

        assertEq(ERC1967_PROXY_STORAGE_SLOT, bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));

        assertEq(MockUUPSUpgrade(proxy).implementation(), logicV1);
        assertEq(vm.load(proxy, ERC1967_PROXY_STORAGE_SLOT), bytes32(uint256(uint160(logicV1))));
    }

    /* ------------- deployProxyAndCall() ------------- */

    /// expect Upgraded(address) to be emitted
    function test_deployProxyAndCall_emit() public {
        vm.expectEmit(true, false, false, false);

        emit Upgraded(logicV1);

        proxy = deployProxyAndCall(logicV1, "");
    }

    /// expect proxy to call `init` during deployment
    function test_deployProxyAndCall_init() public {
        proxy = deployProxyAndCall(logicV1, abi.encodePacked(MockUUPSUpgradeV1.init.selector));

        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 1);
    }

    /// call a nonexistent init function
    function test_deployProxyAndCall_fail_fallback() public {
        vm.expectRevert();

        proxy = deployProxyAndCall(logicV1, abi.encodePacked(bytes4(uint32(0x123456))));
    }

    /// deploy and upgrade to an invalid address (EOA)
    function test_deployProxyAndCall_fail_NotAContract(address logic, bytes memory initCalldata) public {
        vm.assume(logic.code.length == 0);
        vm.expectRevert(NotAContract.selector);

        proxy = deployProxyAndCall(logic, initCalldata);
    }

    /// deploy and upgrade to contract with an invalid uuid
    function test_deployProxyAndCall_fail_InvalidUUID(bytes memory initCalldata) public {
        address logic = address(new LogicInvalidUUID());

        vm.expectRevert(InvalidUUID.selector);

        proxy = deployProxyAndCall(address(logic), initCalldata);
    }

    /// deploy and upgrade to a contract that doesn't implement proxiableUUID
    function test_deployProxyAndCall_fail_NonexistentUUID(bytes memory initCalldata) public {
        address logic = address(new LogicNonexistentUUID());

        vm.expectRevert();

        proxy = deployProxyAndCall(address(logic), initCalldata);
    }

    /// call a reverting init function
    function test_deployProxyAndCall_fail_RevertOnInit() public {
        vm.expectRevert(RevertOnInit.selector);

        proxy = deployProxyAndCall(logicV2, abi.encodePacked(MockUUPSUpgradeV2.initReverts.selector));
    }

    /// note: bubbling up errors on create is not directly possible
    function testFail_deployProxyAndCall_fail_initRevertsWithMessage(bytes memory message) public {
        // vm.expectRevert(message);

        bytes memory initCalldata = abi.encodeWithSelector(MockUUPSUpgradeV2.initRevertsWithMessage.selector, message);

        proxy = deployProxyAndCall(logicV1, initCalldata);
    }

    /* ------------- upgradeToAndCall() ------------- */

    /// expect implementation logic to change on upgrade
    function test_upgradeToAndCall_logic() public {
        // proxy can call v1's setData
        MockUUPSUpgradeV1(proxy).setData(0x3333);

        assertEq(MockUUPSUpgradeV1(proxy).data(), 0x3333); // proxy's data now has changed
        assertEq(MockUUPSUpgradeV1(logicV1).data(), 0x1337); // implementation's data remains unchanged

        // -> upgrade to v2
        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV2, "");

        // test v2 functions
        assertEq(MockUUPSUpgradeV2(proxy).fn(), 6969);
        assertEq(MockUUPSUpgradeV2(proxy).fn2(), 3141);

        // make sure data remains unchanged (though returned as address now)
        assertEq(MockUUPSUpgradeV2(proxy).data(), address(0x3333));

        // only available under v1 logic
        vm.expectRevert();
        MockUUPSUpgradeV1(proxy).setData(0x456);

        // <- upgrade back to v1
        MockUUPSUpgradeV2(proxy).upgradeToAndCall(logicV1, "");

        // v1's setData works again
        MockUUPSUpgradeV1(proxy).setData(0x6666);

        assertEq(MockUUPSUpgradeV1(proxy).data(), 0x6666);

        // only available under v2 logic
        vm.expectRevert();
        MockUUPSUpgradeV2(proxy).fn2();
    }

    /// expect new implementation to be stored
    function test_upgradeToAndCall_implementation() public {
        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV2, "");

        MockUUPSUpgrade(proxy).scrambleStorage(0, 100);

        assertEq(MockUUPSUpgradeV1(proxy).implementation(), logicV2);
        assertEq(vm.load(proxy, ERC1967_PROXY_STORAGE_SLOT), bytes32(uint256(uint160(logicV2))));
    }

    /// expect Upgraded(address) to be emitted
    function test_upgradeToAndCall_emit() public {
        vm.expectEmit(true, false, false, false, proxy);
        emit Upgraded(logicV2);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV2, "");

        vm.expectEmit(true, false, false, false, proxy);
        emit Upgraded(logicV1);

        MockUUPSUpgradeV2(proxy).upgradeToAndCall(logicV1, "");
    }

    /// expect upgradeToAndCall to actually call the function
    function test_upgradeToAndCall_init() public {
        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 0);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV1, abi.encodePacked(MockUUPSUpgradeV1.init.selector));

        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 1);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV1, abi.encodePacked(MockUUPSUpgradeV1.init.selector));

        assertEq(MockUUPSUpgradeV1(proxy).initializedCount(), 2);
    }

    /// upgrade and call a nonexistent init function
    function test_upgradeToAndCall_fail_fallback() public {
        vm.expectRevert();

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV2, abi.encodePacked(bytes4(uint32(0x123456))));
    }

    /// expect reverting function to revert on init
    function test_upgradeToAndCall_fail_RevertOnInit() public {
        vm.expectRevert(RevertOnInit.selector);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV2, abi.encodePacked(MockUUPSUpgradeV2.initReverts.selector));
    }

    /// expect error to bubble up on revert
    function test_upgradeToAndCall_fail_initRevertsWithMessage(string memory message) public {
        vm.expectRevert(bytes(message));

        bytes memory initCalldata = abi.encodeWithSelector(MockUUPSUpgradeV2.initRevertsWithMessage.selector, message);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logicV2, initCalldata);
    }

    /// upgrade to an invalid address (EOA)
    function test_upgradeToAndCall_fail_NotAContract(address logic, bytes memory initCalldata) public {
        vm.assume(logic.code.length == 0);
        vm.expectRevert(NotAContract.selector);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logic, initCalldata);
    }

    /// upgrade to contract with an invalid uuid
    function test_upgradeToAndCall_fail_InvalidUUID() public {
        address logic = address(new LogicInvalidUUID());

        vm.expectRevert(InvalidUUID.selector);

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logic, "");
    }

    /// upgrade to a contract that doesn't implement proxiableUUID
    function test_upgradeToAndCall_fail_NonexistentUUID() public {
        address logic = address(new LogicNonexistentUUID());

        vm.expectRevert();

        MockUUPSUpgradeV1(proxy).upgradeToAndCall(logic, "");
    }
}
