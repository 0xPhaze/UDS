// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/* ============= Storage ============= */

struct EIP2612DS {
    mapping(address => uint256) nonces;
}

// keccak256("diamond.storage.eip.712.permit") == 0x24034dbc71162a0a127c76a8ce123f10641be888cbac564cd2e6e6f5e2c19b81;
bytes32 constant DIAMOND_STORAGE_EIP_712_PERMIT = 0x24034dbc71162a0a127c76a8ce123f10641be888cbac564cd2e6e6f5e2c19b81;

function ds() pure returns (EIP2612DS storage diamondStorage) {
    assembly {
        diamondStorage.slot := DIAMOND_STORAGE_EIP_712_PERMIT
    }
}

/* ============= Errors ============= */

error InvalidSigner();
error PermitDeadlineExpired();

/* ============= EIP712PermitUDS ============= */

abstract contract EIP712PermitUDS {
    /* ------------- Public ------------- */

    function nonces(address owner) public view returns (uint256) {
        return ds().nonces[owner];
    }

    // depends on address(this), so can't be pre-computed
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
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
