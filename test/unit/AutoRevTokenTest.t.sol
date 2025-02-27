// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20, IERC20, IERC20Errors} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {AutoRevToken, Ownable} from "src/AutoRevToken.sol";
import {DeployAutoRevToken} from "script/DeployAutoRevToken.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract AutoRevTokenTest is Test {
    // configuration
    DeployAutoRevToken deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    // contract
    AutoRevToken token;

    // helpers
    address USER1 = makeAddr("user1");
    address USER2 = makeAddr("user2");
    address SPENDER = makeAddr("spender");
    address NEW_OWNER = makeAddr("new-owner");

    uint256 constant STARTING_BALANCE = 500_000_000 ether;
    uint256 constant TOKEN_AMOUNT = 10_000 ether;

    // events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SetFee(uint256 indexed fee);
    event ExcludedFromReward(address indexed account, bool indexed isExcluded);
    event ExcludedFromFee(address indexed account, bool indexed isExcluded);

    // modifiers
    modifier funded(address account) {
        // fund user
        vm.startPrank(token.owner());
        token.transfer(account, STARTING_BALANCE);
        vm.stopPrank();
        _;
    }

    // setup
    function setUp() external {
        deployment = new DeployAutoRevToken();
        (token, helperConfig) = deployment.run();
        networkConfig = helperConfig.getActiveNetworkConfigStruct();
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function calcReflections(address from, address to, uint256 amount)
        internal
        view
        returns (uint256 expectedBalanceFrom, uint256 expectedBalanceTo, uint256 reflectionsFrom, uint256 reflectionsTo)
    {
        uint256 tax = amount * token.getFee() / 10000;
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
                                DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    function test__Initialization() public view {
        assertEq(token.name(), networkConfig.name);
        assertEq(token.symbol(), networkConfig.symbol);
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), networkConfig.totalSupply * 10 ** token.decimals());
        assertEq(token.owner(), networkConfig.initialOwner);
        assertEq(token.balanceOf(networkConfig.initialOwner), networkConfig.totalSupply * 10 ** token.decimals());
    }

    /*//////////////////////////////////////////////////////////////
                                TRANSFER
    //////////////////////////////////////////////////////////////*/
    function test__Transfer(uint256 amount) public funded(USER1) {
        amount = bound(amount, 1, STARTING_BALANCE);

        (uint256 expectedBalanceUser1, uint256 expectedBalanceUser2, uint256 reflectionsUser1, uint256 reflectionsUser2)
        = calcReflections(USER1, USER2, amount);

        vm.prank(USER1);
        token.transfer(USER2, amount);

        assertEq(token.balanceOf(USER1), expectedBalanceUser1 + reflectionsUser1);
        assertEq(token.balanceOf(USER2), expectedBalanceUser2 + reflectionsUser2);
    }

    function test__TransferWithoutFee() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 10_000 ether;

        vm.prank(owner);
        token.excludeFromFee(USER1, true);

        uint256 expectedBalanceUser1 = token.balanceOf(USER1) - amount;
        uint256 expectedBalanceUser2 = token.balanceOf(USER2) + amount;

        vm.prank(USER1);
        token.transfer(USER2, amount);

        assertEq(token.balanceOf(USER1), expectedBalanceUser1);
        assertEq(token.balanceOf(USER2), expectedBalanceUser2);
    }

    function test__TransferWithExcludedFromRewardTo() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 10_000 ether;

        vm.prank(owner);
        token.excludeFromReward(USER2, true);

        (uint256 expectedBalanceUser1, uint256 expectedBalanceUser2, uint256 reflectionsUser1, uint256 reflectionsUser2)
        = calcReflections(USER1, USER2, amount);

        vm.prank(USER1);
        token.transfer(USER2, amount);

        assertEq(token.balanceOf(USER1), expectedBalanceUser1 + reflectionsUser1);
        assertEq(token.balanceOf(USER2), expectedBalanceUser2 + reflectionsUser2);
    }

    function test__TransferWithExcludedFromRewardFrom() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 10_000 ether;

        vm.prank(owner);
        token.excludeFromReward(USER1, true);

        (uint256 expectedBalanceUser1, uint256 expectedBalanceUser2, uint256 reflectionsUser1, uint256 reflectionsUser2)
        = calcReflections(USER1, USER2, amount);

        vm.prank(USER1);
        token.transfer(USER2, amount);

        assertEq(token.balanceOf(USER1), expectedBalanceUser1 + reflectionsUser1);
        assertEq(token.balanceOf(USER2), expectedBalanceUser2 + reflectionsUser2);
    }

    function test__TransferWithExcludedFromRewardFromAndTo() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 10_000 ether;

        vm.startPrank(owner);
        token.excludeFromReward(USER1, true);
        token.excludeFromReward(USER2, true);
        vm.stopPrank();

        (uint256 expectedBalanceUser1, uint256 expectedBalanceUser2, uint256 reflectionsUser1, uint256 reflectionsUser2)
        = calcReflections(USER1, USER2, amount);

        vm.prank(USER1);
        token.transfer(USER2, amount);

        assertEq(token.balanceOf(USER1), expectedBalanceUser1 + reflectionsUser1);
        assertEq(token.balanceOf(USER2), expectedBalanceUser2 + reflectionsUser2);
    }

    function test__TransferByOnwerWhenTransfersDisabled() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 10_000 ether;

        uint256 expectedBalanceOwner = token.balanceOf(owner) - amount;
        uint256 expectedBalanceUser1 = token.balanceOf(USER1) + amount;

        vm.prank(owner);
        token.transfer(USER1, amount);

        assertEq(token.balanceOf(owner), expectedBalanceOwner);
        assertEq(token.balanceOf(USER1), expectedBalanceUser1);
    }

    function test__EmitEvent__Transfer() public funded(USER1) {
        uint256 amount = 10_000 ether;

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER2, amount);

        vm.prank(USER1);
        token.transfer(USER2, amount);
    }

    function test__RevertWhen__TransfersDisabled() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 10000 ether;

        vm.prank(owner);
        token.setFee(10000);

        vm.expectRevert(AutoRevToken.AutoRevToken__TransfersDisabled.selector);

        vm.prank(USER1);
        token.transfer(USER2, amount);
    }

    function test__RevertWhen__TransferWithInsufficientBalance() public funded(USER1) {
        uint256 amount = STARTING_BALANCE + 10 ether;
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, USER1, token.balanceOf(USER1), amount
            )
        );
        vm.prank(USER1);
        token.transfer(USER2, amount);
    }

    function test__RevertWhen__TransferExcludedFromRewardWithInsufficientBalance() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = STARTING_BALANCE + 10 ether;

        vm.prank(owner);
        token.excludeFromReward(USER1, true);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, USER1, token.balanceOf(USER1), amount
            )
        );
        vm.prank(USER1);
        token.transfer(USER2, amount);
    }

    function test__RevertWhen__TransferWithInvalidReceiver() public funded(USER1) {
        uint256 amount = 10000 ether;

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));

        vm.prank(USER1);
        token.transfer(address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER FROM
    //////////////////////////////////////////////////////////////*/

    function test__TransferFrom() public funded(USER1) {
        uint256 amount = 10_000 ether;

        (uint256 expectedBalanceUser1, uint256 expectedBalanceUser2, uint256 reflectionsUser1, uint256 reflectionsUser2)
        = calcReflections(USER1, USER2, amount);

        vm.prank(USER1);
        token.approve(SPENDER, amount);

        vm.prank(SPENDER);
        token.transferFrom(USER1, USER2, amount);

        assertEq(token.balanceOf(USER1), expectedBalanceUser1 + reflectionsUser1);
        assertEq(token.balanceOf(USER2), expectedBalanceUser2 + reflectionsUser2);
    }

    function test__EmitEvent__TransferFrom() public funded(USER1) {
        uint256 amount = 10_000 ether;

        vm.prank(USER1);
        token.approve(SPENDER, amount);

        vm.expectEmit(true, true, true, true);
        emit Transfer(USER1, USER2, amount);

        vm.prank(SPENDER);
        token.transferFrom(USER1, USER2, amount);
    }

    function test__RevertWhen__TransferFromWithInsufficientAllowance() public funded(USER1) {
        uint256 approvalAmount = 100 ether;
        uint256 transferAmount = 200 ether;

        vm.prank(USER1);
        token.approve(USER2, approvalAmount);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector, USER2, approvalAmount, transferAmount
            )
        );

        vm.prank(USER2);
        token.transferFrom(USER1, USER2, transferAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            APPROVE
    //////////////////////////////////////////////////////////////*/
    function test__Approve() public funded(USER1) {
        uint256 amount = 100 ether;

        vm.prank(USER1);
        token.approve(SPENDER, amount);

        assertEq(token.allowance(USER1, SPENDER), amount);
    }

    function test__EmitEvent__Approve() public funded(USER1) {
        uint256 amount = 100 ether;

        vm.expectEmit(true, true, true, true);
        emit Approval(USER1, SPENDER, amount);

        vm.prank(USER1);
        token.approve(SPENDER, amount);
    }

    function test__RevertWhen__ApproveInvalidSpender() public {
        uint256 amount = 100 ether;

        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));

        vm.prank(USER1);
        token.approve(address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                            RENOUNCE OWNERSHIP
    //////////////////////////////////////////////////////////////*/
    function test__RenounceOwnership() public {
        address owner = token.owner();

        vm.prank(owner);
        token.renounceOwnership();

        assertEq(token.owner(), address(0));
    }

    function test__RevertWhen__NotOwnerRenouncesOwnership() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        token.renounceOwnership();
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER OWNERHSIP
    //////////////////////////////////////////////////////////////*/
    function test__TransferOwnership() public {
        address owner = token.owner();

        vm.prank(owner);
        token.transferOwnership(USER1);

        assertEq(token.owner(), USER1);
    }

    function test__RevertWhen__NotOwnerTransfersOwnership() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        token.transferOwnership(USER1);
    }

    /*//////////////////////////////////////////////////////////////
                                SET FEE
    //////////////////////////////////////////////////////////////*/

    function test__SetFee() public {
        address owner = token.owner();
        uint256 newFee = 300;

        vm.prank(owner);
        token.setFee(newFee);

        assertEq(token.getFee(), newFee);
    }

    function test__EmitEvent__SetFee() public {
        address owner = token.owner();
        uint256 newFee = 300;

        vm.expectEmit(true, true, true, true);
        emit SetFee(newFee);

        vm.prank(owner);
        token.setFee(newFee);
    }

    function test__RevertWhen__SetFeeByNotOwner() public {
        uint256 newFee = 300;

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        token.setFee(newFee);
    }

    function test__RevertWhen__SetFeeInvalid() public {
        address owner = token.owner();
        uint256 newFee = 10010;

        vm.expectRevert(AutoRevToken.AutoRevToken__InvalidFee.selector);

        vm.prank(owner);
        token.setFee(newFee);
    }

    /*//////////////////////////////////////////////////////////////
                          EXCLUDE FROM FEE
    //////////////////////////////////////////////////////////////*/

    function test__ExcludeFromFee() public {
        address owner = token.owner();

        vm.prank(owner);
        token.excludeFromFee(USER1, true);

        assertEq(token.isExcludedFromFee(USER1), true);
    }

    function test__EmitEvent__ExcludeFromFee() public {
        address owner = token.owner();

        vm.expectEmit(true, true, true, true);
        emit ExcludedFromFee(USER1, true);

        vm.prank(owner);
        token.excludeFromFee(USER1, true);
    }

    function test__RevertWhen__ExcludedFromFeeByNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        token.excludeFromFee(USER1, true);
    }

    /*//////////////////////////////////////////////////////////////
                          EXCLUDE FROM REWARD
    //////////////////////////////////////////////////////////////*/

    function test__ExcludeFromReward() public {
        address owner = token.owner();

        vm.prank(owner);
        token.excludeFromReward(USER1, true);

        assertEq(token.isExcludedFromReward(USER1), true);
    }

    function test__GetExcludeFromRewardLength() public {
        address owner = token.owner();

        for (uint256 i = 0; i < 50; i++) {
            vm.prank(owner);
            token.excludeFromReward(address(uint160(i)), true);
        }

        assertEq(token.getNumberOfAccountsExcludedFromRewards(), 50);
    }

    function test__IncludeFromReward() public {
        address owner = token.owner();

        vm.prank(owner);
        token.excludeFromReward(USER1, true);

        assertEq(token.getNumberOfAccountsExcludedFromRewards(), 1);

        vm.prank(owner);
        token.excludeFromReward(USER1, false);

        assertEq(token.isExcludedFromReward(USER1), false);
        assertEq(token.getNumberOfAccountsExcludedFromRewards(), 0);
    }

    function test__EmitEvent__ExcludeFromReward() public {
        address owner = token.owner();

        vm.expectEmit(true, true, true, true);
        emit ExcludedFromReward(USER1, true);

        vm.prank(owner);
        token.excludeFromReward(USER1, true);
    }

    function test__RevertWhen__ExcludeFromRewardByNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        token.excludeFromReward(USER1, true);
    }

    function test__RevertWhen__ExcludeFromRewardAlreadySet() public {
        address owner = token.owner();

        vm.expectRevert(AutoRevToken.AutoRevToken__ValueAlreadySet.selector);

        vm.prank(owner);
        token.excludeFromReward(USER1, false);
    }

    function test__RevertWhen__ExcludeFromRewardListTooLong() public {
        address owner = token.owner();

        for (uint256 i = 0; i < 100; i++) {
            vm.prank(owner);
            token.excludeFromReward(address(uint160(i)), true);
        }

        assertEq(token.getNumberOfAccountsExcludedFromRewards(), 100);

        vm.expectRevert(AutoRevToken.AutoRevToken__ExcludedFromRewardListTooLong.selector);

        vm.prank(owner);
        token.excludeFromReward(USER1, true);
    }

    /*//////////////////////////////////////////////////////////////
                          WITHDRAW TOKENS
    //////////////////////////////////////////////////////////////*/

    function test__WithdrawTokens() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 1000 ether;

        vm.prank(USER1);
        token.transfer(address(token), amount);

        vm.prank(owner);
        token.withdrawTokens(address(token), USER2);

        assertEq(token.balanceOf(USER2), amount);
    }

    function test__RevertWhen__WithdrawTokensByNotOwner() public funded(USER1) {
        uint256 amount = 1000 ether;

        vm.prank(USER1);
        token.transfer(address(token), amount);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER1));

        vm.prank(USER1);
        token.withdrawTokens(address(token), USER2);
    }

    function test__RevertWhen__WithdrawTokensTransferFails() public funded(USER1) {
        address owner = token.owner();
        uint256 amount = 1000 ether;

        vm.prank(USER1);
        token.transfer(address(token), amount);

        uint256 contractBalance = token.balanceOf(address(token));

        vm.mockCall(
            address(token), abi.encodeWithSelector(token.transfer.selector, USER2, contractBalance), abi.encode(false)
        );

        vm.expectRevert(AutoRevToken.AutoRevToken__TokenTransferFailed.selector);

        vm.prank(owner);
        token.withdrawTokens(address(token), USER2);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/
    function test__GetTotalFees(uint256 amount) public funded(USER1) {
        amount = bound(amount, 1, STARTING_BALANCE);
        uint256 fee = token.getFee() * amount / 10000;

        vm.prank(USER1);
        token.transfer(USER2, amount);

        assertEq(token.getTotalFees(), fee);
    }
}
