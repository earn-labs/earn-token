// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {AutoRevToken} from "src/AutoRevToken.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract Deploy is Script {
    function run() external returns (AutoRevToken, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (string memory name, string memory symbol, uint256 totalSupply, address initialOwner) =
            config.activeNetworkConfig();

        vm.startBroadcast();
        AutoRevToken myContract = new AutoRevToken(name, symbol, totalSupply, initialOwner);
        vm.stopBroadcast();
        return (myContract, config);
    }
}
