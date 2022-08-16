// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MyNFTUpgradeableV1} from "./ExampleNFT.sol";

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
source .env && forge script Deploy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

3. (optional) if verification failed
```sh
source .env && forge script Deploy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --resume --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

*/

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // deploys the implementation contract
        address implementation = address(new MyNFTUpgradeableV1());

        // insert parameters if the init function has any
        bytes memory initParameters = abi.encode(/* parameter1, parameter2 */); // prettier-ignore
        // encode calldata for init call
        bytes memory initCalldata = abi.encodePacked(MyNFTUpgradeableV1.init.selector, initParameters);

        // deploys the proxy contract and calls MyNFTUpgradeableV1.init() in the context of the proxy
        address proxy = address(new ERC1967Proxy(implementation, initCalldata));

        integrationTest(MyNFTUpgradeableV1(proxy));

        console.log("proxy:", proxy);
        console.log("implementation:", implementation);

        vm.stopBroadcast();
    }

    /// @notice the script will fail if these conditions aren't met
    function integrationTest(MyNFTUpgradeableV1 proxy) internal view {
        require(proxy.owner() == msg.sender);

        require(keccak256(abi.encode(proxy.name())) == keccak256(abi.encode("Non-fungible Contract")));
        require(keccak256(abi.encode(proxy.symbol())) == keccak256(abi.encode("NFT")));
    }
}
