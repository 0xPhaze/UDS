// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ------------- storage

// keccak256("diamond.storage.eip.712.permit") == 0x24034dbc71162a0a127c76a8ce123f10641be888cbac564cd2e6e6f5e2c19b81;
bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = 0x24034dbc71162a0a127c76a8ce123f10641be888cbac564cd2e6e6f5e2c19b81;

function s() pure returns (EIP2612DS storage diamondStorage) {
    assembly { diamondStorage.slot := DIAMOND_STORAGE_EIP_712_PERMIT } // prettier-ignore
}

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// ------------- errors

error InvalidSigner();
error DeadlineExpired();

/// @notice EIP712Permit compatible with diamond storage
/// @author phaze (https://github.com/0xPhaze/UDS)
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate)
abstract contract EIP712PermitUDS {
    /* ------------- public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return s().nonces[owner];
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256("EIP712"),
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
        bytes32 s_
    ) internal virtual returns (bool) {
        if (deadline < block.timestamp) revert DeadlineExpired();

        uint256 nonce = s().nonces[owner]++;

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
                s_
            );

            if (recoveredAddress == address(0) || recoveredAddress != owner) revert InvalidSigner();
        }

        return true;
    }
}
