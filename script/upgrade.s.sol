// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MyNFTUpgradeableV2} from "./ExampleNFT.sol";

import "forge-std/Script.sol";

/* 

1. Run script (NOTE: replace `PROXY_ADDRESS=...` below with your deployed address or add it to your .env)

```sh
source .env && PROXY_ADDRESS=0x123 forge script upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

4. (optional) if verification failed
```sh
source .env && PROXY_ADDRESS=0x123 forge script upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --resume --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```
*/

contract upgrade is Script {
    function run() external {
        address proxyAddress = tryLoadEnvVar("PROXY_ADDRESS");
        require(proxyAddress.code.length != 0, "Invalid proxy address. Address contains no code.");

        vm.startBroadcast();

        // deploys the new implementation contract
        address implementation = address(new MyNFTUpgradeableV2());

        // call the init function upon deployment
        bytes memory initCalldata = abi.encodePacked(MyNFTUpgradeableV2.init.selector);

        // calls upgradeTo and MyNFTUpgradeableV2.init() in the context of the proxy
        MyNFTUpgradeableV2(proxyAddress).upgradeToAndCall(implementation, initCalldata);

        integrationTest(MyNFTUpgradeableV2(proxyAddress));

        console.log("new implementation:", implementation);

        vm.stopBroadcast();
    }

    function tryLoadEnvVar(string memory key) internal returns (address) {
        try vm.envAddress(key) returns (address addr) {
            return addr;
        } catch {
            console.log("Make sure `%s=` is set in your `.env` file.", key);
            revert("Could not load environment variable.");
        }
    }

    /// @notice the script will fail if these conditions aren't met
    function integrationTest(MyNFTUpgradeableV2 proxy) internal view {
        require(proxy.owner() == msg.sender);

        require(keccak256(abi.encode(proxy.name())) == keccak256(abi.encode("Non-fungible Contract V2")));
        require(keccak256(abi.encode(proxy.symbol())) == keccak256(abi.encode("NFTV2")));
    }
}
