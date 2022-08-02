// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MyNFTUpgradeableV2} from "./ExampleNFT.sol";

import "forge-std/Script.sol";

/* 

1. make sure your .env file contains the following variables:
```.env
RPC_URL=https://eth-rinkeby.alchemyapi.io/v2/Q_w...
ETHERSCAN_KEY=NZSD...
PRIVATE_KEY=0x1234...
```

2. insert address of deployed proxy for `DEPLOYED_PROXY_ADDRESS` in script below

3. run script

```sh
source .env && forge script script/Upgrade.s.sol:Upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

4. (optional) if verification failed
```sh
source .env && forge script script/Upgrade.s.sol:Upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --resume --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

*/

// insert deployed proxy address here!
address constant DEPLOYED_PROXY_ADDRESS = address(0x1234);

contract Upgrade is Script {
    function run() external {
        require(DEPLOYED_PROXY_ADDRESS != address(0x1234), "insert your deployed proxy address in the script");

        vm.startBroadcast();

        // deploys the new implementation contract
        address implementation = address(new MyNFTUpgradeableV2());

        // call the init function upon deployment
        bytes memory initCalldata = abi.encodePacked(MyNFTUpgradeableV2.init.selector);

        // calls upgradeTo and MyNFTUpgradeableV2.init() in the context of the proxy
        MyNFTUpgradeableV2(DEPLOYED_PROXY_ADDRESS).upgradeToAndCall(implementation, initCalldata);

        integrationTest(MyNFTUpgradeableV2(DEPLOYED_PROXY_ADDRESS));

        console.log("new implementation:", implementation);

        vm.stopBroadcast();
    }

    /// @notice the script will fail if these conditions aren't met
    function integrationTest(MyNFTUpgradeableV2 proxy) internal view {
        require(proxy.owner() == msg.sender);

        require(keccak256(abi.encode(proxy.name())) == keccak256(abi.encode("Non-fungible Contract V2")));
        require(keccak256(abi.encode(proxy.symbol())) == keccak256(abi.encode("NFTV2")));
    }
}
