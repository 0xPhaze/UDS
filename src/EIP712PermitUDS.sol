// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {InitializableUDS} from "./InitializableUDS.sol";

/* ============= Storage ============= */

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// keccak256("diamond.storage.eip-2612") == 0x849c7f5b4ebbadaf9ded81b9b15e8a309fe7876a607687fda84fe7e7355a02ee;
bytes32 constant DIAMOND_STORAGE_EIP_2612 = 0x849c7f5b4ebbadaf9ded81b9b15e8a309fe7876a607687fda84fe7e7355a02ee;

function ds() pure returns (EIP2612DS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_EIP_2612
    }
}

/* ============= Errors ============= */

error InvalidSigner();
error PermitDeadlineExpired();

/* ============= EIP712PermitUDS ============= */

abstract contract EIP712PermitUDS is InitializableUDS {
    // uint256 internal immutable INITIAL_CHAIN_ID;

    // bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    // function __EIP2612_init() internal initializer {
    //     INITIAL_CHAIN_ID = block.chainid;
    //     INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    // }

    /* ------------- Public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return ds().nonces[owner];
    }

    // FIX check gas usage on these
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        // return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
        return computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256("ERC721"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /* ------------- internal ------------- */

    function _usePermit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual returns (bool) {
        if (deadline < block.timestamp) revert PermitDeadlineExpired();

        uint256 nonce = ds().nonces[owner]++;

        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonce,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner) revert InvalidSigner();
        }

        return true;
    }
}
