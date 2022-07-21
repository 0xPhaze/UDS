// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MyNFTUpgradeableV2} from "./MyNFT.sol";

import "forge-std/Script.sol";

/* 

1. make sure your .env file contains the following variables:
```.env
RPC_URL=https://eth-rinkeby.alchemyapi.io/v2/Q_w...
ETHERSCAN_KEY=NZSD...
PRIVATE_KEY=0x1234...
```

2. run script

```sh
source .env && forge script script/Upgrade.s.sol:Upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

3. (optional) if verification failed
```sh
source .env && forge script script/Upgrade.s.sol:Upgrade --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --resume --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

*/

contract Upgrade is Script {
    function run() external {
        vm.startBroadcast();

        // insert deployed address here!
        address deployedProxy = address(0x1234);

        // deploys the new implementation contract
        address implementation = address(new MyNFTUpgradeableV2());

        // call the init function upon deployment
        bytes memory initCalldata = abi.encodePacked(MyNFTUpgradeableV2.init.selector);

        // calls upgradeTo and MyNFTUpgradeableV2.init() in the context of the proxy
        MyNFTUpgradeableV2(deployedProxy).upgradeToAndCall(implementation, initCalldata);

        vm.stopBroadcast();
    }
}
