// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ReflectionToken, Ownable} from "src/ReflectionToken.sol";
import {DeployReflectionToken} from "script/DeployReflectionToken.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Transfer, TransferFrom, Approve} from "script/Interactions.s.sol";

contract ReflectionTokenIntegrationTest is Test {
    // configuration
    DeployReflectionToken deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contract
    ReflectionToken token;

    // helpers
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address SPENDER = makeAddr("spender");
    address NEW_OWNER = makeAddr("new-owner");

    uint256 constant STARTING_BALANCE = 500_000_000 ether;
    uint256 constant TOKEN_AMOUNT = 10_000 ether;
    uint256 constant PRECISION = 10000 * 1e18;

    // modifiers
    modifier funded(address account) {
        // fund user
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();
        _;
    }

    // setup
    function setUp() external virtual {
        deployment = new DeployReflectionToken();
        (token, helperConfig) = deployment.run();
        networkConfig = helperConfig.getActiveNetworkConfigStruct();
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    function fund(address account) public {
        // fund user
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();
    }

    function calcReflections(address from, address to, uint256 amount)
        internal
        view
        returns (uint256 expectedBalanceFrom, uint256 expectedBalanceTo, uint256 reflectionsFrom, uint256 reflectionsTo)
    {
        uint256 tax = amount * token.getFee() / PRECISION;
        uint256 totalSupply = token.totalSupply();

        expectedBalanceFrom = token.balanceOf(from) - amount;
        expectedBalanceTo = token.balanceOf(to) + amount - tax;

        reflectionsFrom = tax * expectedBalanceFrom / (totalSupply - tax);
        reflectionsTo = tax * expectedBalanceTo / (totalSupply - tax);

        if (token.isExcludedFromReward(from) && !token.isExcludedFromReward(to)) {
            reflectionsFrom = 0;
            reflectionsTo = tax * expectedBalanceTo / (totalSupply - expectedBalanceFrom - tax);
        } else if (!token.isExcludedFromReward(from) && token.isExcludedFromReward(to)) {
            reflectionsTo = 0;
            reflectionsFrom = tax * expectedBalanceFrom / (totalSupply - expectedBalanceTo - tax);
        } else if (token.isExcludedFromReward(from) && token.isExcludedFromReward(to)) {
            reflectionsFrom = 0;
            reflectionsTo = 0;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/
    function test__integration__Transfer() public funded(msg.sender) {
        Transfer transfer = new Transfer();
        uint256 amount = transfer.transferAmount();
        address receiver = transfer.account();

        (uint256 expectedBalanceFrom, uint256 expectedBalanceTo, uint256 reflectionsFrom, uint256 reflectionsTo) =
            calcReflections(msg.sender, receiver, amount);

        transfer.transfer(address(token));

        assertEq(token.balanceOf(msg.sender), expectedBalanceFrom + reflectionsFrom);
        assertEq(token.balanceOf(receiver), expectedBalanceTo + reflectionsTo);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER FROM
    //////////////////////////////////////////////////////////////*/
    function test__integration__TransferFrom() public funded(msg.sender) {
        TransferFrom transferFrom = new TransferFrom();
        uint256 amount = transferFrom.transferAmount();
        address sender = transferFrom.sender();
        address receiver = transferFrom.receiver();

        fund(sender);

        (uint256 expectedBalanceFrom, uint256 expectedBalanceTo, uint256 reflectionsFrom, uint256 reflectionsTo) =
            calcReflections(sender, receiver, amount);

        vm.prank(sender);
        token.approve(msg.sender, amount);

        transferFrom.transferFrom(address(token));

        assertEq(token.balanceOf(sender), expectedBalanceFrom + reflectionsFrom);
        assertEq(token.balanceOf(receiver), expectedBalanceTo + reflectionsTo);
    }

    /*//////////////////////////////////////////////////////////////
                               APPROVE
    //////////////////////////////////////////////////////////////*/
    function test__integration__Approve() public funded(msg.sender) {
        Approve approve = new Approve();
        approve.approve(address(token));

        assertEq(token.allowance(msg.sender, approve.account()), approve.transferAmount());
    }
}
