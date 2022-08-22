// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MyNFTUpgradeableV2} from "./ExampleNFT.sol";

import "forge-std/Script.sol";

/* 

1. Make sure your .env file now contains `PROX_ADDRESS`:
```.env
PROXY_ADDRESS=0x1234...
RPC_URL=https://eth-rinkeby.alchemyapi.io/v2/Q_w...
ETHERSCAN_KEY=NZSD...
PRIVATE_KEY=0xabcd...
```

3. Run script

```sh
source .env && forge script Upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

4. (optional) if verification failed
```sh
source .env && forge script Upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --resume --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```
*/

contract Upgrade is Script {
    function run() external {
        address proxyAddress = tryLoadEnvVar("PROXY_ADDRESS");

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
            console.log("Make sure `%=` is set in your environment.", key);
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
