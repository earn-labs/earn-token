// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

import {ReflectionToken} from "src/ReflectionToken.sol";
import {DeployReflectionToken} from "script/DeployReflectionToken.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Handler} from "test/invariant/Handler.t.sol";

contract ReflectionTokenInvariantTest is StdInvariant, Test {
    // configuration
    DeployReflectionToken deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;
    Handler handler;

    // contract
    ReflectionToken token;

    // setup
    function setUp() external {
        deployment = new DeployReflectionToken();
        (token, helperConfig) = deployment.run();

        handler = new Handler(token);

        console.log("Excluding addreses from rewards...");
        excludeSender(address(0));
        excludeSender(address(token));
        excludeSender(address(handler));

        console.log("Registering functions...");
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = Handler.transferTokens.selector;
        selectors[1] = Handler.transferFromTokens.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));

        console.log("Register handler...");
        targetContract(address(handler));
    }

    function invariant__TokenSupply() public view {
        uint256 sumOfBalances;
        uint256 numOfActors = handler.actorCount();

        for (uint256 index = 0; index < numOfActors; index++) {
            sumOfBalances += token.balanceOf(handler.actorAtIndex(index));
        }

        uint256 contractBalance = token.balanceOf(address(handler));
        assertApproxEqAbs(token.totalSupply(), sumOfBalances + contractBalance, 1000);

        console.log("Total supply: ", token.totalSupply());
        console.log("Total Balance: ", sumOfBalances + contractBalance);
        console.log("Sum of balances: ", sumOfBalances);
        console.log("Contract balance: ", contractBalance);
    }

    function invariant__TotalFees() public view {
        console.log("Total Fees: ", token.getTotalFees());
        console.log("Ghost Total Fees: ", handler.ghost_totalFees());
        assertEq(handler.ghost_totalFees(), token.getTotalFees());
    }

    function invariant__Reflections() public view {
        uint256 numOfActors = handler.actorCount();
        for (uint256 index = 0; index < numOfActors; index++) {
            address actor = handler.actorAtIndex(index);
            if (!token.isExcludedFromReward(actor)) {
                if (handler.lastBalance(actor) >= 1e18) {
                    // console.logString(handler.userType(actor));
                    // console.log("Actor %d last balance: %d", index, handler.lastBalance(actor));
                    // console.log("Actor %d balance of: %d", index, token.balanceOf(actor));
                    assertGt(token.balanceOf(actor), handler.lastBalance(actor));
                } else if (
                    handler.lastBalance(actor) == 0 && !handler.ghost_transferToSelf() && handler.ghost_totalFees() > 0
                ) {
                    // console.logString(handler.userType(actor));
                    // console.log("Actor %d last balance: %d", index, handler.lastBalance(actor));
                    // console.log("Actor %d balance of: %d", index, token.balanceOf(actor));

                    // approximately 0 as there can be rounding error while converting from r to t space.
                    assertApproxEqAbs(token.balanceOf(actor), 0, 1);
                }
            } else {
                console.log("Actor %d balance: %d", index, token.balanceOf(actor));
            }
        }
    }

    function invariant__CallSummary() public view {
        handler.callSummary();
    }
}
