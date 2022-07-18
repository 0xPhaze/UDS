// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "/proxy/ERC1967Proxy.sol";

contract LogicV1 is MockUUPSUpgrade(1) {
    uint256 public data = 0x1337;
    uint256 public initializedCount;
    bool public callLogged;

    function init() public {
        ++initializedCount;
    }

    function fn() public pure returns (uint256) {
        return 1337;
    }

    function setData(uint256 newData) public {
        data = newData;
    }

    fallback() external {
        callLogged = true;
    }
}

contract LogicV2 is MockUUPSUpgrade(2) {
    address public data = address(0x42);

    function initReverts() public pure {
        revert("revert on init");
    }

    function fn() public pure returns (uint256) {
        return 6969;
    }

    function fn2() public pure returns (uint256) {
        return 3141;
    }
}

contract LogicRevertingUUID {}

contract LogicInvalidUUID {
    bytes32 public proxiableUUID = 0x0000000000000000000000000000000000000000000000000000000000001234;
}

contract TestUUPSUpgrade is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    address proxy;
    LogicV1 logicV1;
    LogicV2 logicV2;

    function deployProxy(address implementation, bytes memory initCalldata) internal virtual returns (address) {
        return address(new ERC1967Proxy(address(implementation), initCalldata));
    }

    function setUp() public virtual {
        logicV1 = new LogicV1();
        logicV2 = new LogicV2();

        proxy = deployProxy(address(logicV1), "");
    }

    /* ------------- setUp() ------------- */

    function test_setUp() public {
        assertEq(logicV1.version(), 1);
        assertEq(logicV2.version(), 2);
        assertEq(LogicV1(proxy).version(), 1);

        assertEq(logicV1.fn(), 1337);
        assertEq(logicV2.fn(), 6969);
        assertEq(logicV2.fn2(), 3141);
        assertEq(LogicV1(proxy).fn(), 1337);

        assertEq(logicV1.data(), 0x1337);
        assertEq(logicV2.data(), address(0x42));
        assertEq(LogicV1(proxy).data(), 0);

        assertEq(LogicV1(proxy).callLogged(), false);
        assertEq(LogicV1(proxy).initializedCount(), 0);

        // make sure that s().implementation is not
        // located in sequential storage slot
        // @note shouldn't this affect initcalled
        MockUUPSUpgrade(proxy).scrambleStorage();
        assertEq(MockUUPSUpgrade(proxy).implementation(), address(logicV1));
    }

    /* ------------- gas ------------- */

    function testGas_deploy() public {
        deployProxy(address(logicV1), "");
    }

    function testGas_upgradeTo() public {
        LogicV1(proxy).upgradeTo(address(logicV2));
    }

    function testGas_upgradeToAndCall() public {
        LogicV1(proxy).upgradeToAndCall(address(logicV2), abi.encodePacked(LogicV2.fn.selector));
    }

    function testGas_version() public view {
        LogicV1(proxy).version();
    }

    /* ------------- deploy() ------------- */

    event Upgraded(address indexed implementation);

    /// expect Upgraded(address) to be emitted
    function test_deploy_emit() public {
        vm.expectEmit(true, false, false, false);
        emit Upgraded(address(logicV1));

        proxy = deployProxy(address(logicV1), "");
    }

    /// expect deploy to actually call the function
    function test_deployAndCallInit() public {
        proxy = deployProxy(address(logicV1), abi.encodePacked(LogicV1.init.selector));

        assertEq(LogicV1(proxy).initializedCount(), 1);
    }

    /// deploy and upgrade to an invalid address (EOA)
    function test_deployAndCall_fail_NotAContract() public {
        vm.expectRevert(NotAContract.selector);

        proxy = deployProxy(bob, "");
    }

    /// deploy and upgrade to contract with an invalid uuid
    function test_deployAndCall_fail_InvalidUUID() public {
        address logic = address(new LogicInvalidUUID());

        vm.expectRevert(InvalidUUID.selector);

        proxy = deployProxy(address(logic), "");
    }

    /// deploy and upgrade to a contract that doesn't implement proxiableUUID
    /// this one reverts differently depending on proxy..
    function testFail_deployAndCall_fail_InvalidUUID() public {
        address logic = address(new LogicInvalidUUID());

        // vm.expectRevert(InvalidUUID.selector);

        proxy = deployProxy(address(logic), "");
    }

    /// upgrade to v2 and call a reverting init function
    function test_deployAndCall_fail_Revert() public {
        vm.expectRevert("revert on init");

        proxy = deployProxy(address(logicV2), abi.encodePacked(LogicV2.initReverts.selector));
    }

    /* ------------- upgradeTo() ------------- */

    /// expect Upgraded(address) to be emitted
    function test_upgradeTo_emit() public {
        // expect Upgraded(logicV2) to be emitted by proxy
        vm.expectEmit(true, false, false, false, proxy);
        emit Upgraded(address(logicV2));

        LogicV1(proxy).upgradeTo(address(logicV2));

        // expect Upgraded(logicV1) to be emitted by proxy
        vm.expectEmit(true, false, false, false, proxy);
        emit Upgraded(address(logicV1));

        LogicV2(proxy).upgradeTo(address(logicV1));
    }

    /// expect implementation to be stored correctly
    function test_upgradeTo_implementation() public {
        LogicV1(proxy).upgradeTo(address(logicV2));

        assertEq(LogicV1(proxy).implementation(), address(logicV2));
    }

    /// expect implementation logic to change on upgrade
    function test_upgradeTo_logic() public {
        // proxy can call v1's setData
        LogicV1(proxy).setData(0x3333);

        assertEq(LogicV1(proxy).data(), 0x3333); // proxy's data now has changed
        assertEq(logicV1.data(), 0x1337); // implementation's data remains unchanged

        // -> upgrade to v2
        LogicV1(proxy).upgradeTo(address(logicV2));

        // test v2 functions
        assertEq(LogicV2(proxy).fn(), 6969);
        assertEq(LogicV2(proxy).fn2(), 3141);

        // make sure data remains unchanged (though returned as address now)
        assertEq(LogicV2(proxy).data(), address(0x3333));

        // only available under v1 logic
        vm.expectRevert();
        LogicV1(proxy).setData(0x456);

        // <- upgrade back to v1
        LogicV2(proxy).upgradeTo(address(logicV1));

        // v1's setData works again
        LogicV1(proxy).setData(0x6666);

        assertEq(LogicV1(proxy).data(), 0x6666);

        // only available under v2 logic
        vm.expectRevert();
        LogicV2(proxy).fn2();
    }

    /// expect upgradeToAndCall to actually call the function
    function test_upgradeToAndCallInit() public {
        LogicV1(proxy).upgradeToAndCall(address(logicV1), abi.encodePacked(LogicV1.init.selector));

        assertEq(LogicV1(proxy).initializedCount(), 1);
    }

    /// upgrade to an invalid address (EOA)
    function test_upgradeToAndCall_fail_NotAContract() public {
        vm.expectRevert(NotAContract.selector);

        LogicV1(proxy).upgradeToAndCall(bob, "");
    }

    /// upgrade to contract with an invalid uuid
    function test_upgradeToAndCall_fail_InvalidUUID() public {
        address logic = address(new LogicInvalidUUID());

        vm.expectRevert(InvalidUUID.selector);

        LogicV1(proxy).upgradeTo(logic);
    }

    /// upgrade to a contract that doesn't implement proxiableUUID
    /// this one reverts differently depending on proxy..
    function testFail_upgradeToAndCall_fail_InvalidUUID() public {
        address logic = address(new LogicInvalidUUID());

        // vm.expectRevert(InvalidUUID.selector);

        LogicV1(proxy).upgradeTo(logic);
    }

    /// upgrade to v2 and call a reverting init function
    /// expect revert reason to bubble up
    function test_upgradeToAndCall_fail_Revert() public {
        vm.expectRevert("revert on init");

        LogicV1(proxy).upgradeToAndCall(address(logicV2), abi.encodePacked(LogicV2.initReverts.selector));
    }
}
