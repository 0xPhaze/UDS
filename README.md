# Upgradeable Contracts Using Diamond Storage

A collection of upgradeable contracts compatible with diamond storage.

## Contracts
```ml
src
├── AccessControlUDS.sol - "OpenZeppelin's Access Control"
├── EIP712PermitUDS.sol - "EIP712 Permit"
├── ERC20UDS.sol - "Solmate's ERC20"
├── ERC20DripUDS.sol - "ERC20 with dripping abilities"
├── ERC721UDS.sol - "Solmate's ERC721"
├── ERC1155UDS.sol - "Solmate's ERC1155"
├── InitializableUDS.sol - "contains `initializer` modifier for upgradeable contracts"
├── OwnableUDS.sol - "Ownable"
└── proxy
    ├── ERC1967Proxy.sol - "ERC1967 proxy implementation"
    ├── ERC1967ProxyWithImmutableArgs.sol - "ERC1967 proxy, supports up to 3 immutable args"
    └── UUPSUpgrade.sol - "Minimal UUPSUpgrade"
```

Benefits over using Openzeppelin's upgradeable contracts:
- No worrying about calculating storage gaps or adding/removing inheritance, because of diamond storage
- "Re-initialize" proxies (calling init on an already deployed proxy) is possible
- Removes possibility of an [uninitialized implementation](https://medium.com/immunefi/wormhole-uninitialized-proxy-bugfix-review-90250c41a43a)


## What is diamond storage?

[Diamond Storage](https://medium.com/1milliondevs/new-storage-layout-for-proxy-contracts-and-diamonds-98d01d0eadb)
keeps contract storage data in structs at arbitrary locations as opposed to in sequence.
This means that storage collisions between contracts don't have to be dealt with.
However, the same caveats apply to the diamond storage structs internally when upgrading contracts,
though these are easier to deal with.
The free function `s()` returns a reference to the struct's storage location, which is required to
read/write any state.


## What is a proxy?

A proxy contract delegates all calls to an implementation contract.
Mostly, it behaves as though it was the implementation contract itself.
Storage is written to the proxy contract and only the code logic is read/used from the implementation contract.
This means that the only interactions (in its intended way) that have a noticeable effect on the blockchain happen with the proxy contract.
A proxy can be upgradeable and swap out the address pointing to the implementation contract for a new one.
This can be thought of as changing the contract's runtime code.

An important thing to note is that upgradeable contracts can't rely on a constructor for initializing variables
as the constructor is only run once during deployment and isn't stored as part of the deployed bytecode / runtime code.
When deploying a proxy, the proxy's constructor is run (and storage variables in the proxy contract can be set here), 
however, a proxy won't be able to call the implementation contract's constructor or be affected by it.

This is why it is useful to have functions that are internal and/or public secured by the `initializer`
modifier (found in `InitializableUDS.sol`). These functions are then only callable during a proxy contract's deployment (in the constructor).
In contrast to OpenZeppelin's `initializer`, these functions won't ever be callable on the implementation contract
and can be used to "re-initialize"!
Though one should not forget to run all initializing functions, as, for example, a contract's upgradeability could be lost, if
`UUPSUpgrade`'s `_authorizeUpgrade` is secured by the `onlyOwner` modifier, but `OwnableUDS`' `__Ownable__init` was never called.

## Caveats

These contracts are a work in progress and should not be used in production. Use at your own risk.
As mentioned before, there exist some notable and important differences to common implementations.
Make sure you are aware of these.