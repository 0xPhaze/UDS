// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "../proxy/ERC1967Proxy.sol";
import {MockUUPSUpgrade} from "./mocks/MockUUPSUpgrade.sol";

import "../EIP712PermitUDS.sol";

bytes32 constant PERMIT_TYPEHASH = keccak256(
    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
);

contract MockEIP712Permit is MockUUPSUpgrade(1), EIP712PermitUDS {
    function usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s_
    ) public returns (bool) {
        return _usePermit(owner, spender, value, deadline, v, r, s_);
    }
}

/// @author Solmate (https://github.com/Rari-Capital/solmate/)
contract TestEIP712PermitUDS is Test {
    address bob = address(0xb0b);
    address alice = address(0xbabe);
    address tester = address(this);

    MockEIP712Permit permit;

    function setUp() public {
        permit = new MockEIP712Permit();
    }

    /* ------------- upgradeTo() ------------- */

    function test_permit() public {
        uint256 privateKey = 0xBEEF;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    permit.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp))
                )
            )
        );

        bool success = permit.usePermit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);

        assertTrue(success);
        assertEq(permit.nonces(owner), 1);
    }

    function test_permit_fail_InvalidSigner() public {
        uint256 privateKey = 0xBEEF;
        address owner = vm.addr(privateKey);

        // bad timestamp
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    permit.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp + 1))
                )
            )
        );

        vm.expectRevert(InvalidSigner.selector);
        permit.usePermit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);

        // bad nonce
        (v, r, s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    permit.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 1, block.timestamp))
                )
            )
        );

        vm.expectRevert(InvalidSigner.selector);
        permit.usePermit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);

        // bad nonce; replay
        (v, r, s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    permit.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp))
                )
            )
        );

        permit.usePermit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);

        vm.expectRevert(InvalidSigner.selector);
        permit.usePermit(owner, address(0xCAFE), 1e18, block.timestamp, v, r, s);
    }

    function test_permit_fail_DeadlineExpired() public {
        uint256 privateKey = 0xBEEF;
        address owner = vm.addr(privateKey);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    permit.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, address(0xCAFE), 1e18, 0, block.timestamp))
                )
            )
        );

        vm.expectRevert(DeadlineExpired.selector);
        permit.usePermit(owner, address(0xCAFE), 1e18, block.timestamp - 1, v, r, s);
    }
}
