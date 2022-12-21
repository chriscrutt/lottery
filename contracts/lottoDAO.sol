/**

MINT TOKENS TO PEOPLE RESTARTING CONTRACT
ADD UNCHECKED OR OTHER THINGS TO ACCUMULATED ETHER
 */

/**
 * The LottoDAO contract is a decentralized autonomous organization (DAO) that handles a lottery
 * game. It is based on the LottoGratuity contract, which is an abstract contract that handles the
 * distribution of winnings to beneficiaries. The LottoDAO contract also includes a
 * LottoRewardsToken contract, which is an ERC20 token that allows users to start staking and
 * receive rewards.
 *
 * The LottoDAO contract has several functions that allow users to interact with the contract. The
 * startStaking() function allows users to start staking their tokens and receive rewards. The
 * withdrawFees() function allows users to withdraw any accumulated fees they have earned through
 * the DAO. The _logWinningPlayer() function records the winner, winnings, and block number in the
 * winning history array.
 *
 * The LottoDAO contract also has two private functions that are used to calculate the accumulated
 * ether for a user. The _accumulatedEtherLinear() function uses a linear search to find the
 * accumulated ether for a user, while the _accumulatedEtherBinary() function uses a binary search
 * to find the accumulated ether for a user. Both functions take in an address as a parameter and
 * return the accumulated ether as a uint256 value.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lottoGratuity.sol";
import "./ERC80085.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LottoRewardsToken is ERC80085, Ownable {
    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) ERC20Permit(name) {} // solhint-disable-line no-empty-blocks

    receive() external payable onlyOwner {} // solhint-disable-line no-empty-blocks

    function startStaking() public {
        _startStaking(_msgSender());
    }

    function startStaking(address account) public onlyOwner {
        _startStaking(account);
    }

    function transferEth(address to, uint256 amount) public onlyOwner {
        _transferEth(to, amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

abstract contract LottoDAO is LottoGratuity {
    using Math for uint256;

    // will handle each lotto win
    struct WinningInfoDAO {
        address winner;
        uint256 winningAmount;
        uint256 blockNumber;
        uint256 feeAmount;
        uint256 totalStakedSupply;
    }

    WinningInfoDAO[] private _winningHistory;

    LottoRewardsToken public lottoRewardsToken;

    uint256 private _daoGratuity;
    uint256 private _lastPot;

    uint256 private _rewardsPerBlock;

    /**
     * @dev Constructor for the LottoGratuity contract. Initializes the LottoRewardsToken contract,
     * sets the rewards per block and DAO gratuity, and allows the caller to start staking tokens.
     * @param maxBeneficiaries The maximum number of beneficiaries allowed for the contract.
     * @param daoGratuity_ The percentage of winnings that go to the DAO gratuity * 1000
     */
    constructor(
        string memory rewardTokenName_,
        string memory rewardTokenSymbol_,
        uint8 maxBeneficiaries,
        uint256 daoGratuity_
    ) LottoGratuity(maxBeneficiaries, _msgSender(), 0) {
        lottoRewardsToken = new LottoRewardsToken(
            rewardTokenName_,
            rewardTokenSymbol_
        );
        _rewardsPerBlock = 21e18;
        _daoGratuity = daoGratuity_;
        _swapBeneficiary(0, address(lottoRewardsToken), daoGratuity_);
        lottoRewardsToken.mint(_msgSender(), 1);
        startStaking();
    }

    /**
     * @dev Allows the caller to start staking tokens.
     */
    function startStaking() public {
        lottoRewardsToken.startStaking(_msgSender());
    }

    /**
     * @dev Withdraws accumulated fees for the caller, using either a linear search or binary
     * search depending on the length of the caller's transfer history.
     */
    function withdrawFees() public {
        address account = _msgSender();
        uint256 len = lottoRewardsToken
            .holderData(account)
            .transferSnaps
            .length;
        if (len < 19) {
            lottoRewardsToken.transferEth(
                account,
                _accumulatedEtherLinear(account) -
                    lottoRewardsToken.holderData(account).rewardsWithdrawn
            );
        } else {
            lottoRewardsToken.transferEth(
                account,
                _accumulatedEtherBinary(account) -
                    lottoRewardsToken.holderData(account).rewardsWithdrawn
            );
        }
    }

    /**
     * @dev Pays out the specified amount to the contract owner and updates the last pot value.
     * @param amount The amount to be paid out.
     */
    function _payout(uint256 amount) internal virtual override {
        _lastPot = amount;
        super._payout(amount);
    }

    /**
     * @dev Records the winner, winnings, and block number in the winning history array.
     * @param account The address of the winning player.
     * @param winnings The amount won by the player.
     */
    function _logWinningPlayer(
        address account,
        uint256 winnings
    ) internal virtual override {
        _winningHistory.push(
            WinningInfoDAO({
                winner: account,
                winningAmount: winnings,
                blockNumber: endingBlock(),
                // feeAmount: (_lastPot * _daoGratuity) / 1000,
                feeAmount: _lastPot.mulDiv(_daoGratuity, 1000),
                totalStakedSupply: lottoRewardsToken.totalStakedSupply()
            })
        );
    }

    /**
     * @notice Rewards the caller with tokens based on the number of blocks that have passed since
     * the last reward was issued.
     * @dev Rewards per block decrease by 0.1% every block.
     */
    function _start() internal virtual override {
        super._start();

        uint256 blockDif = block.number -
            _winningHistory[_winningHistory.length - 1].blockNumber;

        uint256 tokensToReward = 0;
        uint256 tmpRewardsPerBlock = _rewardsPerBlock;

        for (uint256 i = 0; i < blockDif; ++i) {
            tokensToReward += tmpRewardsPerBlock;
            tmpRewardsPerBlock = tmpRewardsPerBlock.mulDiv(
                999,
                1000,
                Math.Rounding.Up
            );
        }

        _rewardsPerBlock = tmpRewardsPerBlock;
        lottoRewardsToken.mint(_msgSender(), tokensToReward);
    }

    /// @notice Calculates the accumulated ether of a given account using binary search
    /// @param account Address of the account to check
    /// @return eth Accumulated ether of the given account
    function _accumulatedEtherBinary(
        address account
    ) private view returns (uint eth) {
        // get person whos accumulated ether we're checking
        ERC80085.Snapshot[] memory array1 = lottoRewardsToken
            .holderData(account)
            .transferSnaps;

        // get array of winning information
        WinningInfoDAO[] memory array2 = _winningHistory;

        // loop through each value in array2
        for (uint i = 0; i < array2.length; i++) {
            // initialize low and high indices for binary search in array1
            uint low = 0;
            uint high = array1.length - 1;

            // binary search for closest but not greater value in array1
            while (low <= high) {
                uint mid = (low + high) / 2;
                // check if value at mid is equal to current value in array2
                if (array1[mid].blockNumber == array2[i].blockNumber) {
                    // exact match found
                    // add value to eth
                    eth += array2[i].feeAmount.mulDiv(
                        array1[mid].snapBalance,
                        array2[i].totalStakedSupply
                    );
                    // exit loop
                    break;
                } else if (array1[mid].blockNumber > array2[i].blockNumber) {
                    // value at mid is greater than current value in array2
                    // search left of mid
                    high = mid - 1;
                } else {
                    // value at mid is lesser than current value in array2
                    // search right of mid
                    low = mid + 1;
                }
            }
            // check if closest but not greater value was not found
            if (low > high) {
                // check if value is not between first and last values in array1
                if (low != 0 || high != array1.length - 1) {
                    // check if value is after last value in array1
                    if (high == array1.length - 1) {
                        // use last value in array1 as closest but not greater value
                        eth += array2[i].feeAmount.mulDiv(
                            array1[high].snapBalance,
                            array2[i].totalStakedSupply
                        );
                    } else if (low != 0) {
                        // value is between first and last values in array1
                        // find value with smallest difference
                        if (
                            array2[i].blockNumber - array1[high].blockNumber <
                            array1[low].blockNumber - array2[i].blockNumber
                        ) {
                            // use value before current value in array1 as closest but not greater
                            // value
                            eth += array2[i].feeAmount.mulDiv(
                                array1[high].snapBalance,
                                array2[i].totalStakedSupply
                            );
                        } else {
                            // use value after current value in array1 as closest but not greater
                            // value
                            eth += array2[i].feeAmount.mulDiv(
                                array1[low].snapBalance,
                                array2[i].totalStakedSupply
                            );
                        }
                    }
                }
            }
        }
    }

    /// @notice Calculates the accumulated ether of a given account using a linear search
    /// @param account Address of the account to check
    /// @return eth Accumulated ether of the given account
    function _accumulatedEtherLinear(
        address account // address of the account to check
    ) private view returns (uint eth) {
        // returns the accumulated ether of the account
        // get the transfer snapshot data for the given account
        ERC80085.Snapshot[] memory array1 = lottoRewardsToken
            .holderData(account)
            .transferSnaps;

        // get the winning history data for the contract
        WinningInfoDAO[] memory array2 = _winningHistory;

        // initialize loop variables
        uint i = 0;
        uint j = 0;

        // loop through both arrays simultaneously
        while (i < array1.length && j < array2.length) {
            // if the block numbers are the same
            if (array1[i].blockNumber == array2[j].blockNumber) {
                // increment the accumulated ether by the fee amount multiplied by the snap balance
                // of the account and divided by the total staked supply
                eth += array2[j].feeAmount.mulDiv(
                    array1[i].snapBalance,
                    array2[j].totalStakedSupply
                );
                // move to the next block in both arrays
                i++;
                j++;
            }
            // if the block number in "array1" is greater than the block number in "array2"
            else if (array1[i].blockNumber > array2[j].blockNumber) {
                // if this is not the first block in "array1"
                if (i != 0) {
                    // check which snap balance has a smaller difference in block numbers
                    if (
                        array2[j].blockNumber - array1[i - 1].blockNumber <
                        array1[i].blockNumber - array2[j].blockNumber
                    ) {
                        // increment the accumulated ether by the fee amount multiplied by the snap
                        // balance of the previous block in "array1" and divided by the total
                        // staked supply
                        eth += array2[j].feeAmount.mulDiv(
                            array1[i - 1].snapBalance,
                            array2[j].totalStakedSupply
                        );
                    }
                    // if the current block in "array1" has a smaller difference in block numbers
                    else {
                        // increment the accumulated ether by the fee amount multiplied by the snap
                        // balance of the current lock in "array1" and divided by the total staked
                        // supply
                        eth += array2[j].feeAmount.mulDiv(
                            array1[i].snapBalance,
                            array2[j].totalStakedSupply
                        );
                    }
                }
                // move to the next block in "array2"
                j++;
            }
            // if the block number in "array2" is greater than the block number in "array1"
            else {
                // move to the next block in "array1"
                i++;
            }
        }
    }
}
