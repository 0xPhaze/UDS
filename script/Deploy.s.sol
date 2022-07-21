// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967Proxy} from "/proxy/ERC1967Proxy.sol";
import {MyNFTUpgradeableV1} from "./MyNFT.sol";

import "forge-std/Script.sol";

/* 

1. create a .env file with the following variables:
```.env
RPC_URL=https://eth-rinkeby.alchemyapi.io/v2/Q_w...
ETHERSCAN_KEY=NZSD...
PRIVATE_KEY=0x1234...
```

2. run script

```sh
source .env && forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

3. (optional) if verification failed
```sh
source .env && forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --resume --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

*/

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // deploys the implementation contract
        address implementation = address(new MyNFTUpgradeableV1());

        // call the init function upon deployment
        bytes memory initParameters = abi.encode(/* parameter1, parameter2 */); // prettier-ignore
        bytes memory initCalldata = abi.encodePacked(MyNFTUpgradeableV1.init.selector, initParameters);

        // creates the proxy contract and
        // calls MyNFTUpgradeableV1.init() in the context of the proxy
        new ERC1967Proxy(implementation, initCalldata);

        vm.stopBroadcast();
    }
}
