# Upgradeable Contracts Using Diamond Storage

A collection of upgradeable contracts compatible with diamond storage.

## Contracts
```ml
src
├── auth
│   ├── AccessControlUDS.sol - "OpenZeppelin's Access Control"
│   ├── EIP712PermitUDS.sol - "EIP712 Permit"
│   ├── InitializableUDS.sol - "contains `initializer` modifier for upgradeable contracts"
│   └── OwnableUDS.sol - "Ownable"
├── proxy
│   ├── ERC1967Proxy.sol - "ERC1967 proxy implementation"
│   ├── ERC1967ProxyWithImmutableArgs.sol - "ERC1967 proxy, supports up to 3 immutable args"
│   └── UUPSUpgrade.sol - "Minimal UUPS upgradeable contract"
└── tokens
    ├── ERC20UDS.sol - "Solmate's ERC20"
    ├── ERC20DripUDS.sol - "ERC20 with dripping abilities"
    ├── ERC20RewardsUDS.sol - "ERC20 with fixed reward accrual"
    ├── ERC1155UDS.sol - "Solmate's ERC1155"
    └── ERC721UDS.sol - "Solmate's ERC721"
```


## Installation

Install with [Foundry](https://github.com/foundry-rs/foundry)
```sh
forge install 0xPhaze/UDS
```

## Deploying an Upgradeable Contract

### Implementation

The implementation contract, needs inherit from [UUPSUpgrade](./src/UUPSUpgrade.sol)
and the `_authorizeUpgrade` function must be overriden (and protected).

**Example of an upgradeable ERC721**

```solidity
import {ERC721UDS} from "UDS/tokens/ERC721UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {InitializableUDS} from "UDS/auth/InitializableUDS.sol";

contract UpgradeableERC721 is UUPSUpgrade, ERC721UDS, InitializableUDS, OwnableUDS {
    function init() public initializer {
        __Ownable_init();
        __ERC721_init("My NFT", "NFT");
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return ...
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}
```

The example uses [OwnableUDS](./src/auth/OwnableUDS.sol) and [InitializableUDS](./src/auth/InitializableUDS.sol).
To see a full example

### Deploying the Proxy Contract

```solidity
import {ERC1967Proxy} from "/proxy/ERC1967Proxy.sol";

address implementation = ...;

bytes memory initCalldata = abi.encodeWithSelector(init.selector, param1, param2);

address proxyAddress = new ERC1967Proxy(implementation, initCalldata);
```

### Upgrading a Proxy Contract

```solidity
import {UUPSUpgrade} from "/proxy/UUPSUpgrade.sol";

UUPSUpgrade(deployedProxy).upgradeToAndCall(implementation, initCalldata);
```

A full example using [Foundry](https://book.getfoundry.sh) and [Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting)
can be found here [Deploy](./script/Deploy.s.sol) and here [Upgrade](./script/Upgrade.s.sol).


## Benefits

Benefits over using Openzeppelin's upgradeable contracts:
- No worrying about calculating storage gaps or adding/removing inheritance, because of diamond storage
- Simplified dependencies and contracts
- "Re-initialize" proxies (calling init on an already deployed proxy) is possible
- Removes possibility of an [uninitialized implementation](https://medium.com/immunefi/wormhole-uninitialized-proxy-bugfix-review-90250c41a43a)


## What is Diamond Storage?

[Diamond Storage](https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb)
keeps contract storage data in structs at arbitrary locations as opposed to in sequence.
This means that storage collisions between contracts don't have to be dealt with.
However, the same caveats apply to the diamond storage structs internally when upgrading contracts,
though these are easier to deal with.
The free function `s()` returns a reference to the struct's storage location, which is required to
read/write any state.


## What is a Proxy?

A proxy contract delegates all calls to an implementation contract.
This means that it runs the code/logic of the implementation contract is executed in the context of the proxy contract.
If storage is read from or written to, it happens in the proxy itself.
The implementation is (generally) not intended to be interacted with directly.
It only serves as a reference for the proxy on how to execute functions.
For the most part, a proxy behaves as though it was the implementation contract itself.

A proxy can be upgradeable and swap out the address pointing to the implementation contract for a new one.
This can be thought of as changing the contract's runtime code.
The code for running an upgrade is left to be handled by the implementation contract (for UUPS proxies).

Generally, upgradeable contracts can't rely on a constructor for initializing variables.
If the implementation contains a constructor, its code is only run once during deployment (in the implementation contract's context and not in the proxy's context).
The constructor isn't part of the deployed bytecode / runtime code and generally doesn't affect a proxy (often deployed at a later time).

This is why it is useful to have functions that are internal and/or public secured by the `initializer`
modifier (found in `InitializableUDS.sol`). These functions are then only callable during a proxy contract's deployment and before any new upgrade has completed.
In contrast to OpenZeppelin's `initializer`, these functions won't ever be callable on the implementation contract and can be run again, allowing "re-initialization" (as long as they are run during an upgrade).
Forgetting to run all initializing functions can be dangerous. 
For example, a contract's upgradeability could be lost, if
`UUPSUpgrade`'s `_authorizeUpgrade` is secured by the `onlyOwner` modifier, but `OwnableUDS`' `__Ownable__init` was never called.

## Caveats

These contracts are a work in progress and should not be used in production. Use at your own risk.
As mentioned before, there exist some notable and important differences to common implementations.
Make sure you are aware of these.