// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        string name;
        string symbol;
        uint256 totalSupply;
        address initialOwner;
    }

    NetworkConfig public activeNetworkConfig;

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    string constant NAME = "AutoRevToken";
    string constant SYMBOL = "ART";
    uint256 constant TOTAL_SUPPLY = 1_000_000_000;

    constructor() {
        if (block.chainid == 8453 || block.chainid == 123) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 84532 || block.chainid == 84531) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          CHAIN CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            name: NAME,
            symbol: SYMBOL,
            totalSupply: TOTAL_SUPPLY,
            initialOwner: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF
        });
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            name: NAME,
            symbol: SYMBOL,
            totalSupply: TOTAL_SUPPLY,
            initialOwner: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF
        });
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        // vm.startBroadcast();
        // vm.stopBroadcast();

        return NetworkConfig({
            name: NAME,
            symbol: SYMBOL,
            totalSupply: TOTAL_SUPPLY,
            initialOwner: 0x7Bb8be3D9015682d7AC0Ea377dC0c92B0ba152eF
        });
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getActiveNetworkConfigStruct() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
