// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";

import {AddressSet, AddressSets, STARTER_ADDRESS} from "test/invariant/AddressSets.sol";
import {ReflectionToken} from "src/ReflectionToken.sol";

contract Handler is CommonBase, StdCheats, StdUtils, Test {
    using AddressSets for AddressSet;

    // state variables
    uint256 constant PRECISION = 10000 * 1e18;
    uint256 constant MIN_BALANCE = 1000e18;

    AddressSet _actors;
    address _currentActor;

    ReflectionToken public token;

    mapping(bytes32 => uint256) public calls;

    mapping(address => uint256) public lastBalance;
    mapping(address => uint256) public currentBalance;
    mapping(address => string) public userType;

    uint256 public ghost_fee;
    uint256 public ghost_totalFees;
    uint256 public ghost_transferZeroTokens;
    uint256 public ghost_transferFromZeroTokens;
    bool public ghost_transferToSelf;

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
    constructor(ReflectionToken token_) {
        token = token_;

        address owner = token.owner();
        address firstActor = makeAddr("firstActor");

        vm.startPrank(owner);
        token.setFee(200);
        token.excludeFromFee(address(this), true);
        token.excludeFromReward(address(this), true);
        token.transfer(address(this), token.balanceOf(owner));
        vm.stopPrank();

        for (uint256 i = 0; i < 25; i++) {
            address actor = makeAddr(string.concat("actor", vm.toString(i)));
            fundActor(actor);
            _actors.add(actor);
        }
        // _actors.add(firstActor);

        console.log("First actor balance: ", token.balanceOf(firstActor));
        console.log("Handler Token Balance", token.balanceOf(address(this)));
        console.log("Owner Token Balance", token.balanceOf(owner));
        console.log("Handler setup.");
    }

    // helper functions
    function actorCount() external view returns (uint256) {
        return _actors.count();
    }

    function actorAtIndex(uint256 index) external view returns (address) {
        return _actors.getAddressAtIndex(index);
    }

    function fundActor(address actor) public {
        token.transfer(actor, 10_000_000 ether);
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
        // _actors.add(msg.sender);
        // if (token.balanceOf(msg.sender) < MIN_BALANCE) {
        //     fundActor(msg.sender);
        // }

        address receiver = _actors.rand(receiverSeed);

        // prevent transfer to self
        ghost_transferToSelf = false;
        if (_currentActor == receiver) {
            ghost_transferToSelf = true;
            return;
        }

        // prevent small amounts
        uint256 actorBalance = token.balanceOf(_currentActor);
        if (actorBalance < MIN_BALANCE) {
            fundActor(_currentActor);
        }

        amount = bound(amount, MIN_BALANCE, token.balanceOf(_currentActor));

        // Record balances before transfer for all actors
        uint256 fee = token.getFee() * amount / PRECISION;
        for (uint256 i = 0; i < _actors.count(); i++) {
            address actor = _actors.getAddressAtIndex(i);
            if (actor == _currentActor) {
                // console.log("Sender");
                userType[actor] = "Sender";
                lastBalance[actor] = token.balanceOf(actor) - amount;
            } else if (actor == receiver) {
                // console.log("Receiver");
                userType[actor] = "Receiver";
                lastBalance[actor] = token.balanceOf(actor) + amount - fee;
            } else {
                // console.log("Holder");
                userType[actor] = "Holder";
                lastBalance[actor] = token.balanceOf(actor);
            }
        }

        vm.prank(_currentActor);
        token.transfer(receiver, amount);

        if (!token.isExcludedFromFee(_currentActor)) {
            ghost_totalFees += fee;
        }
    }

    function transferFromTokens(uint256 actorSeed, uint256 spenderSeed, uint256 receiverSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transferTokens")
    {
        // _actors.add(msg.sender);
        // if (token.balanceOf(msg.sender) < MIN_BALANCE) {
        //     fundActor(msg.sender);
        // }

        address spender = _actors.rand(spenderSeed);
        address receiver = _actors.rand(receiverSeed);

        // prevent transfer to self
        ghost_transferToSelf = false;
        if (_currentActor == receiver) {
            ghost_transferToSelf = true;
            return;
        }

        uint256 actorBalance = token.balanceOf(_currentActor);
        if (actorBalance < MIN_BALANCE) {
            fundActor(_currentActor);
        }

        amount = bound(amount, MIN_BALANCE, token.balanceOf(_currentActor));

        // Record balances before transfer for all actors
        uint256 fee = token.getFee() * amount / PRECISION;
        for (uint256 i = 0; i < _actors.count(); i++) {
            address actor = _actors.getAddressAtIndex(i);
            if (actor == _currentActor) {
                // console.log("Sender");
                userType[actor] = "Sender";
                lastBalance[actor] = token.balanceOf(actor) - amount;
            } else if (actor == receiver) {
                // console.log("Receiver");
                userType[actor] = "Receiver";
                lastBalance[actor] = token.balanceOf(actor) + amount - fee;
            } else {
                // console.log("Holder");
                userType[actor] = "Holder";
                lastBalance[actor] = token.balanceOf(actor);
            }
        }

        vm.prank(_currentActor);
        token.approve(spender, amount);

        vm.prank(spender);
        token.transferFrom(_currentActor, receiver, amount);

        if (!token.isExcludedFromFee(_currentActor)) {
            ghost_totalFees += fee;
        }
    }
}
