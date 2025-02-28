// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import {AddressSet, AddressSets, STARTER_ADDRESS} from "test/invariant/AddressSets.sol";
import {AutoRevToken} from "src/AutoRevToken.sol";

contract Handler is CommonBase, StdCheats, StdUtils, Test {
    using AddressSets for AddressSet;

    // state variables
    uint256 constant PRECISION = 10000 * 1e18;

    AddressSet _actors;
    address _currentActor;

    AutoRevToken public token;

    mapping(bytes32 => uint256) public calls;

    uint256 public ghost_totalFees;
    uint256 public ghost_transferZeroTokens;
    uint256 public ghost_transferFromZeroTokens;

    // modifiers
    modifier createActor() {
        _currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        _currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    // constructor
    constructor(AutoRevToken token_) {
        token = token_;

        address owner = token.owner();
        address firstActor = makeAddr("firstActor");

        vm.startPrank(owner);
        token.setFee(200);
        token.excludeFromFee(address(this), true);
        token.excludeFromReward(address(this), true);
        token.transfer(address(this), token.balanceOf(owner));
        vm.stopPrank();

        _actors.add(firstActor);

        console.log("First actor balance: ", token.balanceOf(firstActor));
        console.log("Handler Token Balance", token.balanceOf(address(this)));
        console.log("Owner Token Balance", token.balanceOf(owner));
    }

    // helper functions
    function actorCount() external view returns (uint256) {
        return _actors.count();
    }

    function actorAtIndex(uint256 index) external view returns (address) {
        return _actors.getAddressAtIndex(index);
    }

    function callSummary() external view {
        console.log("\nCall summary:");
        console.log("-------------------");
        console.log("transferTokens", calls["transferTokens"]);

        console.log("-------------------");
        console.log("transferToken with zero tokens: ", ghost_transferZeroTokens);
    }

    // test functions
    function transferTokens(uint256 actorSeed, uint256 receiverSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transferTokens")
    {
        _actors.add(msg.sender);
        address receiver = _actors.rand(receiverSeed);

        uint256 actorBalance = token.balanceOf(_currentActor);
        if (actorBalance == 0) {
            console.log("Account with zero balance: ", _currentActor);
            uint256 fundedAmount = bound(amount, 1000, 10_000_000 ether);
            token.transfer(_currentActor, fundedAmount);
            assert(token.balanceOf(_currentActor) == actorBalance + fundedAmount);
        }

        amount = bound(amount, 1, token.balanceOf(_currentActor));

        vm.prank(_currentActor);
        token.transfer(receiver, amount);

        uint256 fee = token.getFee() * amount / PRECISION;
        if (!token.isExcludedFromFee(_currentActor)) {
            ghost_totalFees += fee;
        }
        // {
        //     console.log("Amount: ", amount);
        //     console.log("Transfer Amount: ", amount - fee);
        //     console.log("Fee: ", fee);
        //     console.log("Total Fees: ", token.getTotalFees());
        //     console.log("Ghost Total Fees: ", ghost_totalFees);
        // }
    }
}
