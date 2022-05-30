# Upgradeable Contracts Using Diamond Storage

A collection of commonly used contracts using diamond storage.

Why use UUPSUpgradeV.sol (in contrast to Openzeppelin's UUPSUpgrade.sol)?

- No worrying about storage gaps or adding/removing inheritance (Diamond Storage)
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
├── AccessControlUDS.sol - "OpenZeppelin's Access Control adapted for Diamond Storage"
├── EIP712PermitUDS.sol - "EIP712 Permit"
├── ERC20UDS.sol - "Solmate's ERC20 adapted for Diamond Storage"
├── ERC721UDS.sol - "Solmate's ERC721 adapted for Diamond Storage"
├── ERC1155UDS.sol - "Solmate's ERC1155 adapted for Diamond Storage"
├── InitializableUDS.sol - "contains `initializer` modifier for upgradeable contracts using UUPSUpgradeV"
├── OwnableUDS.sol - "Ownable Upgradeable"
└── proxy
    ├── ERC1822Versioned.sol - "ERC1822 extended with proxiableVersion"
    ├── ERC1967VersionedUDS.sol - "ERC1967, additionally keeps track of implementation version"
    └── UUPSUpgradeV.sol - "UUPSUpgrade.sol extended with proxiableVersion"
```
