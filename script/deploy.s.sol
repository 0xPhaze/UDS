// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1967Proxy} from "UDS/proxy/ERC1967Proxy.sol";
import {MyNFTUpgradeableV1} from "./ExampleNFT.sol";

import "forge-std/Script.sol";

/* 
For a more complete example (of deploying, upgrading & keeping track of proxies),
have a look at https://github.com/0xPhaze/upgrade-scripts.

Steps to run these scripts:

1. Create a `.env` file with the following variables:
```.env
RPC_URL=https://eth-rinkeby.alchemyapi.io/v2/Q_w...
ETHERSCAN_KEY=NZSD...
PRIVATE_KEY=0x1234...
```

Make sure it's called `.env`!

2. Run script

```sh
source .env && forge script deploy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

3. (optional) if verification failed
```sh
source .env && forge script deploy --rpc-url $RPC_URL  --private-key $PRIVATE_KEY --resume --verify --etherscan-api-key $ETHERSCAN_KEY -vvvv
```

4. Store deployed proxy address in your `.env` file: `PROXY_ADDRESS=...`.
*/

contract deploy is Script {
    MyNFTUpgradeableV1 myNFT;

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

        vm.stopBroadcast();

        myNFT = MyNFTUpgradeableV1(proxy);

        integrationTest();

        console.log("implementation:", implementation);
        console.log("Add `PROXY_ADDRESS=%s` to your .env", proxy);
    }

    /// @notice the script will fail if these conditions aren't met
    function integrationTest() internal view {
        require(myNFT.owner() == msg.sender);

        require(keccak256(abi.encode(myNFT.name())) == keccak256(abi.encode("Non-fungible Contract")));
        require(keccak256(abi.encode(myNFT.symbol())) == keccak256(abi.encode("NFT")));
    }
}
