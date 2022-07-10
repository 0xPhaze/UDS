# Upgradeable Contracts Using diamond storage

A collection of commonly used contracts using diamond storage.

Why use UUPSUpgradeV.sol (in contrast to Openzeppelin's UUPSUpgrade.sol)?

- No worrying about storage gaps or adding/removing inheritance (diamond storage)
- Keeps track of an implementation version which is checked when upgrading
- Only one `initializer` modifier in Initializable.sol
- "Re-initialize" proxies (calling init on an already deployed proxy) is possible
- Removes possiblity of an [uninitialized implementation](https://medium.com/immunefi/wormhole-uninitialized-proxy-bugfix-review-90250c41a43a)

Note: the contract /src/lib/proxy/UUPSUpgradeV.sol is not written using the _diamond standard_,
but is still compatible with EIP-2535.
These contracts simply use _diamond storage_ (where storage is located at some arbitrary slot as opposed to in succession)
to facilitate upgrades.
Using diamond storage means that one does not have to worry about adjusting gaps in upgradeable contracts when adding
new variables or adding new contract inheritance containing storage variables.

```ml
src
├── AccessControlUDS.sol - "OpenZeppelin's Access Control diamond storage compatible"
├── EIP712PermitUDS.sol - "EIP712 Permit"
├── ERC20UDS.sol - "Solmate's ERC20 diamond storage compatible"
├── ERC721UDS.sol - "Solmate's ERC721 diamond storage compatible"
├── ERC1155UDS.sol - "Solmate's ERC1155 diamond storage compatible"
├── InitializableUDS.sol - "contains `initializer` modifier for upgradeable contracts using UUPSUpgradeV"
├── OwnableUDS.sol - "Ownable diamond storage compatible"
└── proxy
    ├── ERC1822Versioned.sol - "ERC1822 extended with proxiableVersion"
    ├── ERC1967Versioned.sol - "ERC1967, keeps track of implementation version"
    ├── ERC1967Proxy.sol - "ERC1967Proxy, proxy implementation"
    └── UUPSUpgradeV.sol - "UUPSUpgrade.sol extended with proxiableVersion"
```
