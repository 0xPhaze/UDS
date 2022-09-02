# Upgradeable Contracts Using Diamond Storage

A collection of upgradeable contracts compatible with diamond storage.

To clarify: these contracts DO NOT require [EIP-2535 Upgradeable Diamond Standard](https://eip2535diamonds.substack.com/p/diamond-upgrades) to be used.
They are simply compatible. In fact, these contracts can also be used without any upgradeability at all.
They can be used in almost exactly the same way as OpenZeppelin's upgradeable contracts, but include some [beneficial properties](#benefits).

## Contracts
```ml
src
├── auth
│   ├── AccessControlUDS.sol - "OpenZeppelin style access-control"
│   ├── EIP712PermitUDS.sol - "EIP712 permit"
│   ├── OwnableUDS.sol - "Owner authorization"
│   ├── PausableUDS.sol - "Make contracts pausable"
│   └── ReentrancyGuardUDS.sol - "Prevent reentrancies"
├── proxy
│   ├── ERC1967Proxy.sol - "ERC1967 proxy implementation"
│   └── UUPSUpgrade.sol - "Minimal UUPS upgradeable contract"
├── utils
│   ├── Initializable.sol - "Allow initializing functions for upgradeable contracts"
│   └── Context.sol - "Allows overrides for meta-transactions"
└── tokens
    ├── ERC20UDS.sol - "Solmate's ERC20"
    ├── ERC1155UDS.sol - "Solmate's ERC1155"
    ├── ERC721UDS.sol - "Solmate's ERC721"
    └── extensions
        ├── ERC20BurnableUDS.sol - "ERC20 burnable"
        └── ERC20RewardUDS.sol - "ERC20 with fixed reward accrual"
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
import {ERC20UDS} from "UDS/tokens/ERC20UDS.sol";
import {OwnableUDS} from "UDS/auth/OwnableUDS.sol";
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";
import {Initializable} from "UDS/utils/Initializable.sol";

contract UpgradeableERC20 is UUPSUpgrade, Initializable, OwnableUDS, ERC20UDS {
    function init() external initializer {
        __Ownable_init();
        __ERC20_init("My Token", "TKN", 18);
        _mint(msg.sender, 1_000_000e18);
    }

    function _authorizeUpgrade() internal override onlyOwner {}
}
```

The example uses [OwnableUDS](./src/auth/OwnableUDS.sol) and [Initializable](./src/utils/Initializable.sol).

### Deploying the Proxy Contract

```solidity
import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";

bytes memory initCall = abi.encodeCall(Implementation.init, (param1, param2));

address proxyAddress = new ERC1967Proxy(implementationAddress, initCall);
```

### Upgrading a Proxy Contract

```solidity
import {UUPSUpgrade} from "UDS/proxy/UUPSUpgrade.sol";

UUPSUpgrade(deployedProxy).upgradeToAndCall(implementationAddress, initCall);
```

A full example using [Foundry](https://book.getfoundry.sh) and [Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting)
can be found here [deploy](./script/deploy.s.sol) and here [upgrade](./script/upgrade.s.sol) 
(note that these examples require you to install project dependencies by running `forge install`).

A more advanced example of upgrading and maintaining proxies 
(including safety checks for storage layout changes) can be found here: [upgrade-scripts](https://github.com/0xPhaze/upgrade-scripts).

## Benefits

Benefits over using Openzeppelin's upgradeable contracts:
- No storage collision through adding/removing inheritance or incorrectly adjusted [storage gaps](https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps), because of diamond storage
- Removes possibility of an [uninitialized implementation](https://medium.com/immunefi/wormhole-uninitialized-proxy-bugfix-review-90250c41a43a)
- Minimal bloat (simplified dependencies and contracts)


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
modifier (found in `Initializable.sol`). These functions are then only callable during a proxy contract's deployment and before any new upgrade has completed.
In contrast to OpenZeppelin's `initializer`, these functions won't ever be callable on the implementation contract and can be run again, allowing "re-initialization" (as long as they are run during an upgrade).
Forgetting to run all initializing functions can be dangerous. 
For example, a contract's upgradeability could be lost, if
`UUPSUpgrade`'s `_authorizeUpgrade` is secured by the `onlyOwner` modifier, but `OwnableUDS`' `__Ownable__init` was never called.

## Caveats

These contracts are a work in progress and should not be used in production. Use at your own risk.
As mentioned before, there exist some notable and important differences to common implementations.
Make sure you are aware of these.