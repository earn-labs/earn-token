// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*//////////////////////////////////////////////////////////////
                                IMPORTS
//////////////////////////////////////////////////////////////*/
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title AutoRevToken
 * @author Nadina Oates
 * @notice This contract implements a token that automatically distributes rewards from fees to all holders based on their balance.
 */
contract AutoRevToken is ERC20, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant MAX = ~uint256(0);

    uint256 private immutable i_tTotalSupply;

    uint256 private s_rTotalSupply;

    address[] private _excludedFromReward;

    uint256 public taxFee = 200; // 200 => 2%
    uint256 public totalFees;

    mapping(address => uint256) private s_rBalances; // balances in r-space
    mapping(address => uint256) private s_tBalances; // balances in t-space

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public isExcludedFromReward;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event SetFee(uint256 indexed fee);
    event ExcludeFromReward(address indexed account, bool indexed isExcluded);
    event ExcludeFromFee(address indexed account, bool indexed isExcluded);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ExcludedFromRewardListTooLong();
    error ValueAlreadySet();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, address initialOwner)
        ERC20(name_, symbol_)
        Ownable(initialOwner)
    {
        i_tTotalSupply = totalSupply_ * 10 ** decimals();

        _excludeFromFee(initialOwner, true);
        _excludeFromFee(address(this), true);
        _mint(initialOwner, i_tTotalSupply);
        transferOwnership(initialOwner);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function setFee(uint256 newTxFee) external onlyOwner {
        taxFee = newTxFee;
        emit SetFee(taxFee);
    }

    function excludeFromFee(address account, bool isExcluded) external onlyOwner {
        _excludeFromFee(account, isExcluded);
    }

    function excludeFromReward(address account, bool isExcluded) external onlyOwner {
        _excludeFromReward(account, isExcluded);
    }

    function withdrawTokens(address tokenAddress, address receiverAddress) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        return tokenContract.transfer(receiverAddress, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function totalSupply() public view override returns (uint256) {
        return i_tTotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (isExcludedFromReward[account]) return s_tBalances[account];
        uint256 rate = _getRate();
        return s_rBalances[account] / rate;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _update(address from, address to, uint256 value) internal override {
        // minting
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            s_rTotalSupply += (MAX - (MAX % value));
            unchecked {
                s_rBalances[to] += s_rTotalSupply;
            }
        } else {
            // regular transfer
            uint256 _taxFee;
            if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
                _taxFee = 0;
            } else {
                _taxFee = taxFee;
            }

            // calc t-values
            uint256 tAmount = value;
            uint256 tTxFee = (tAmount * _taxFee) / 10000;
            uint256 tTransferAmount = tAmount - tTxFee;

            // calc r-values
            uint256 rate = _getRate();
            uint256 rTxFee = tTxFee * rate;
            uint256 rAmount = tAmount * rate;
            uint256 rTransferAmount = rAmount - rTxFee;

            // check balances
            uint256 rFromBalance = s_rBalances[from];
            uint256 tFromBalance = s_tBalances[from];

            if (isExcludedFromReward[from]) {
                if (tFromBalance >= tAmount) {
                    revert ERC20InsufficientBalance(from, balanceOf(from), value);
                }
            } else {
                if (rFromBalance >= rAmount) {
                    revert ERC20InsufficientBalance(from, balanceOf(from), value);
                }
            }

            // Overflow not possible: the sum of all balances is capped by
            // rTotalSupply and tTotalSupply, and the sum is preserved by
            // decrementing then incrementing.
            unchecked {
                // udpate balances in r-space
                s_rBalances[from] = rFromBalance - rAmount;
                s_rBalances[to] += rTransferAmount;

                // update balances in t-space
                if (isExcludedFromReward[from] && isExcludedFromReward[to]) {
                    s_tBalances[from] = tFromBalance - tAmount;
                    s_tBalances[to] += tTransferAmount;
                } else if (isExcludedFromReward[from] && !isExcludedFromReward[to]) {
                    // cannot overflow as tamount is a function of rAmount and _rTotalSupply is mapped to i_tTotalSupply
                    s_tBalances[from] = tFromBalance - tAmount;
                } else if (!isExcludedFromReward[from] && isExcludedFromReward[to]) {
                    // cannot overflow as tAmount is function of rAmount and _rTotalSupply is mapped to i_tTotalSupply
                    s_tBalances[to] += tTransferAmount;
                }

                // reflect fee
                // can never go below zero because rTxFee percentage of
                // current s_rTotalSupply
                s_rTotalSupply = s_rTotalSupply - rTxFee;
                totalFees += tTxFee;
            }
        }

        emit Transfer(from, to, value);
    }
    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _excludeFromFee(address account, bool isExcluded) private {
        isExcludedFromFee[account] = isExcluded;
        emit ExcludeFromFee(account, isExcluded);
    }

    function _excludeFromReward(address account, bool isExcluded) private {
        if (isExcludedFromReward[account] == isExcluded) {
            revert ValueAlreadySet();
        }

        if (_excludedFromReward.length > 100) {
            revert ExcludedFromRewardListTooLong();
        }

        if (isExcluded) {
            if (s_rBalances[account] > 0) {
                uint256 rate = _getRate();
                s_tBalances[account] = s_rBalances[account] / rate;
            }
            isExcludedFromReward[account] = true;
            _excludedFromReward.push(account);
        } else {
            uint256 nExcluded = _excludedFromReward.length;
            for (uint256 i = 0; i < nExcluded; i++) {
                if (_excludedFromReward[i] == account) {
                    _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                    s_tBalances[account] = 0;
                    isExcludedFromReward[account] = false;
                    _excludedFromReward.pop();
                    break;
                }
            }
        }
        emit ExcludeFromReward(account, isExcluded);
    }

    function _getRate() private view returns (uint256) {
        uint256 rSupply = s_rTotalSupply;
        uint256 tSupply = i_tTotalSupply;

        uint256 nExcluded = _excludedFromReward.length;
        for (uint256 i = 0; i < nExcluded; i++) {
            rSupply = rSupply - s_rBalances[_excludedFromReward[i]];
            tSupply = tSupply - s_tBalances[_excludedFromReward[i]];
        }
        if (rSupply < s_rTotalSupply / i_tTotalSupply) {
            rSupply = s_rTotalSupply;
            tSupply = i_tTotalSupply;
        }
        // rSupply always > tSupply (no precision loss)
        uint256 rate = rSupply / tSupply;
        return rate;
    }
}
