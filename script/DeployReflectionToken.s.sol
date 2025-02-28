// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {ReflectionToken} from "src/ReflectionToken.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployReflectionToken is Script {
    function run() external returns (ReflectionToken, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (string memory name, string memory symbol, uint256 totalSupply, uint256 initialFee, address initialOwner) =
            config.activeNetworkConfig();

        vm.startBroadcast();
        ReflectionToken tokenContract = new ReflectionToken(name, symbol, totalSupply, initialFee, initialOwner);
        vm.stopBroadcast();
        return (tokenContract, config);
    }
}
