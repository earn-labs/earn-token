// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {AutoRevToken} from "src/AutoRevToken.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployAutoRevToken is Script {
    function run() external returns (AutoRevToken, HelperConfig) {
        HelperConfig config = new HelperConfig();

        (string memory name, string memory symbol, uint256 totalSupply, uint256 initialFee, address initialOwner) =
            config.activeNetworkConfig();

        vm.startBroadcast();
        AutoRevToken tokenContract = new AutoRevToken(name, symbol, totalSupply, initialFee, initialOwner);
        vm.stopBroadcast();
        return (tokenContract, config);
    }
}
