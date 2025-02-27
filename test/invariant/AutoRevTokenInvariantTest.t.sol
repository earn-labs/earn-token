// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {AutoRevToken} from "src/AutoRevToken.sol";
import {DeployAutoRevToken} from "script/DeployAutoRevToken.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Handler} from "test/invariant/Handler.t.sol";

contract AutoRevTokenInvariantTest is StdInvariant, Test {
    // configuration
    DeployAutoRevToken deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    Handler handler;

    // contract
    AutoRevToken token;

    // setup
    function setUp() external {
        deployment = new DeployAutoRevToken();
        (token, helperConfig) = deployment.run();

        handler = new Handler(token);

        excludeSender(address(0));
        excludeSender(address(token));
        excludeSender(address(handler));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = Handler.transferTokens.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        targetContract(address(handler));
    }

    function invariant__TokenSupply() public view {
        uint256 sumOfBalances;
        uint256 numOfActors = handler.actorCount();

        for (uint256 index = 0; index < numOfActors; index++) {
            sumOfBalances += token.balanceOf(handler.actorAtIndex(index));
        }
        // uint256 ownerBalance = token.balanceOf(token.owner());

        uint256 contractBalance = token.balanceOf(address(handler));
        assertApproxEqAbs(token.totalSupply(), sumOfBalances + contractBalance, 1000);

        console.log("Total supply: ", token.totalSupply());
        console.log("Total Balance: ", sumOfBalances + contractBalance);
        console.log("Sum of balances: ", sumOfBalances);
        console.log("Contract balance: ", contractBalance);
    }

    function invariant__CallSummary() public view {
        handler.callSummary();
    }
}
