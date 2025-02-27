// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        string name;
        string symbol;
        uint256 totalSupply;
        uint256 initialFee; // 10% = 1000
        address initialOwner;
    }

    NetworkConfig public activeNetworkConfig;

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    string constant NAME = "Test 1";
    string constant SYMBOL = "TEST1";
    uint256 constant TOTAL_SUPPLY = 1_000_000_000;

    constructor() {
        if (
            block.chainid == 1 /* ethereum mainnet */ || block.chainid == 8453 /* base mainnet */
                || block.chainid == 43114 /* avax mainnet */ || block.chainid == 123 /*local fork*/
        ) {
            activeNetworkConfig = getMainnetConfig();
        } else if (
            block.chainid == 11155111 /* ethereum sepolia */ || block.chainid == 84532 || block.chainid == 84531 /* base sepolia */
                || block.chainid == 43113 /* avax fuji */
        ) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    /*//////////////////////////////////////////////////////////////
                          CHAIN CONFIGURATIONS
    //////////////////////////////////////////////////////////////*/
    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            name: NAME,
            symbol: SYMBOL,
            totalSupply: TOTAL_SUPPLY,
            initialFee: 10000,
            initialOwner: 0x40A040781E7C28Fc7AEa8E00040e4a0242551A52
        });
    }

    function getTestnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            name: NAME,
            symbol: SYMBOL,
            totalSupply: TOTAL_SUPPLY,
            initialFee: 10000,
            initialOwner: 0xEcA5652Ebc9A3b7E9E14294197A86b02cD8C3A67 // development wallet (trashpirate.base.eth)
        });
    }

    function getAnvilConfig() public pure returns (NetworkConfig memory) {
        // vm.startBroadcast();
        // vm.stopBroadcast();

        return NetworkConfig({
            name: NAME,
            symbol: SYMBOL,
            totalSupply: TOTAL_SUPPLY,
            initialFee: 200,
            initialOwner: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
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
