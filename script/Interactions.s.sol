// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {ReflectionToken} from "src/ReflectionToken.sol";

contract Transfer is Script {
    uint256 public transferAmount = 10_000 ether;
    address public account = makeAddr("user");

    function transfer(address recentContractAddress) public {
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        ReflectionToken(payable(recentContractAddress)).transfer(account, transferAmount);
        console.log("Transfer gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment("ReflectionToken", block.chainid);
        transfer(recentContractAddress);
    }
}

contract TransferFrom is Script {
    uint256 public transferAmount = 10_000 ether;
    address public sender = makeAddr("sender");
    address public receiver = makeAddr("receiver");

    function transferFrom(address recentContractAddress) public {
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        ReflectionToken(payable(recentContractAddress)).transferFrom(sender, receiver, transferAmount);
        console.log("TransferFrom gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment("ReflectionToken", block.chainid);
        transferFrom(recentContractAddress);
    }
}

contract Approve is Script {
    uint256 public transferAmount = 10_000 ether;
    address public account = makeAddr("user");

    function approve(address recentContractAddress) public {
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        ReflectionToken(payable(recentContractAddress)).approve(account, transferAmount);
        console.log("Approval gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
    }

    function run() external {
        address recentContractAddress = DevOpsTools.get_most_recent_deployment("ReflectionToken", block.chainid);
        approve(recentContractAddress);
    }
}
