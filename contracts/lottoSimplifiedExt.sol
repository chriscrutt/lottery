// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./lottoSimplified.sol";
import "./lottoERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title An extention of the lotto contract
/// @author Dr. Doofenshmirtz
/// @notice Grants rewards to a beneficiary and participants of the lottery
/// @dev Right now there is a 1% fee per round. 0.5% goes to a beneficiary and
/// 0.5% goes to token holders. Because it is impossible to automate a smart
/// contract (without centralizing it or using an oracle?), people may earn
/// tokens by (re)starting the lottery after the last one paid out. I may
/// potentially increase fees and such or create a staking contract in order to
/// make it so if tokens are held by exchanges or other things that they won't
/// be taking away eth rewards to those that could be getting them.
/// TODO
/// [ ] staking contract
/// [ ] make sure ~21,000,000 get minted
/// [ ] tx.origin still?
/// [ ] swap/whatever function for `_accumulatedEth` lookup?
/// [ ] eth available function?
/// [ ] rename things to specifiy what is lottery and what is token things
contract LottoSimplifiedExt is LottoTickets {
    // the reward token for running `start`
    LottoToken public lottoToken;

    // the person who gets half the lottery fee
    address public beneficiary;

    // creating the lottery token contract and setting beneficiary to my address
    constructor() {
        lottoToken = new LottoToken();
        beneficiary = address(0x8b1A1aF63bb9b3730f62c56bDa272BCC69dF4CC7);
    }

    /// @notice pays out the winner!
    function payout() external notFromContract {
        require(block.number > endingBlock + pauseBuffer, "round not over yet");
        require(!paid, "already paid out");

        _payout();
    }

    /// @notice withdraw ethereum fees as a token holder
    /// @dev calculates amount of eth available to withdraw here- maybe change?
    /// @param account replacing tx.origin/msg.sender sorry
    function withdraw(address account) external {
        require(areRewardsEnabled(account), "rewards aren't enabled");

        uint256 etherEarned = _accumulatedEther(
            account,
            lottoToken.holderData(account).stakingInfo.startedOnBlock
        );

        require(
            lottoToken.holderData(account).rewardsWithdrawn < etherEarned,
            "withdraws up-to-date"
        );
        uint256 ethToSend = etherEarned -
            lottoToken.holderData(account).rewardsWithdrawn;
        lottoToken.updateWithdrawals(account, ethToSend);
        lottoToken.transferWinnings(payable(account), ethToSend);
    }

    /// @notice enables people/external contracts to check accumulated eth
    /// @param account the person to check how much eth they've accumulated
    function accumulatedEther(address account) external view returns (uint256) {
        if (areRewardsEnabled(account)) {
            return
                _accumulatedEther(
                    account,
                    lottoToken.holderData(account).stakingInfo.startedOnBlock
                );
        } else {
            return 0;
        }
    }

    /// @notice calculates ethereum available to withdraw
    /// @param account the person you're calculating bruh
    function ethAvailable(address account) external view returns (uint256) {
        if (areRewardsEnabled(account)) {
            uint256 etherEarned = _accumulatedEther(
                account,
                lottoToken.holderData(account).stakingInfo.startedOnBlock
            );
            return
                etherEarned - lottoToken.holderData(account).rewardsWithdrawn;
        } else {
            return 0;
        }
    }

    /// @notice starts the lottery
    /// @dev overrides old `start` in order to reward the "starter" tokens for
    /// helping automate the lottery
    function start() public override notFromContract {
        lottoToken.mint(msg.sender, nextTokenReward());
        super.start();
    }

    /// @notice enables earning ethereum fee rewards
    function enableRewards() public {
        lottoToken.enableRewards(msg.sender);
    }

    /// @notice calculates the next token rewards value
    /// @dev `_winningInfo.length` is how many rounds have happened
    function nextTokenReward() public view returns (uint256) {
        return _calculateMintValue(initialTokenReward, _winningInfo.length, 47);
    }

    /// @notice checks to see if ethereum lotto rewards are enabled
    /// @param account to check
    function areRewardsEnabled(address account) public view returns (bool) {
        return lottoToken.areRewardsEnabled(account);
    }

    /// @dev currently gives creator a 0.5% fee. uses SafeMath as to not consume
    /// all gas if division fails for some reason. Resets all ticket and bundle
    /// information as to not conflict when a new lottery is started.
    function _payout() internal override {
        uint256 bal = address(this).balance;
        uint256 moneyWon = Math.mulDiv(bal, 99, 100);
        uint256 fee = bal - moneyWon;
        uint256 toTokenHolders = fee / 2;

        _logWinningPlayer(
            moneyWon,
            lottoToken.totalSupply(),
            lottoToken.totalStakedSupply(),
            toTokenHolders
        );

        super._payout();

        payable(address(lottoToken)).transfer(toTokenHolders);

        payable(beneficiary).transfer(address(this).balance);
    }

    /// @notice calculates the TOTAL rewarded ethereum a token holder has earned
    /// @dev this is convoluted AFFFFF. I'll explain it up here AND down below.
    ///
    /// It gets every token transaction an address has made and sees if they've
    /// made more than one. If so, start with the first one and cycle through
    /// each lottery payout. if it happened before the lottery payout, and their
    /// next transaction happened after, then add their portion of the fee to
    /// the `eth` they've accumulated. Go for each transaction and payout.
    ///
    /// it loops and stops before last user transaction- then checks to see if
    /// any payouts occur after that. This is so we don't each for a nonexistant
    /// array value (like uint256[3] and we search for uint256[5])
    ///
    /// if there is only one transaction just check to see if it happened before
    /// the first payout and reward eth accordingly
    ///
    /// also just added so staking must be enabled in order to get mulla
    ///
    /// @param account the person to check how much eth they've accumulated
    function _accumulatedEther(address account, uint256 enabledOn)
        private
        view
        returns (uint256)
    {
        // gets token holder transaction history
        LottoToken.TokenHolder memory holder = lottoToken.holderData(account);
        // sets eth rewards accumulated to 0
        uint256 eth = 0;

        // if the user has had more than 1 transaction
        if (holder.transferSnaps.length > 1) {
            // start looping through user transactions
            for (uint256 i = 0; i < holder.transferSnaps.length; i++) {
                // start looping through lottery payout history
                for (uint256 j = 0; j < _winningInfo.length; j++) {
                    if (enabledOn < _winningInfo[j].blockNumber) {
                        continue;
                    }
                    // if the current loop isn't the holder's last transaction
                    if (i < holder.transferSnaps.length - 1) {
                        // and it happened at the same time as a payout
                        if (
                            holder.transferSnaps[i].blockNumber ==
                            _winningInfo[j].blockNumber
                        ) {
                            // give them eth according to their share m'kay Karl
                            // eth +=
                            //     (_winningInfo[j].ethFee *
                            //         holder.transferSnaps[i].snapBalance) /
                            //     _winningInfo[j].totalStakedSupply;

                            eth += Math.mulDiv(
                                _winningInfo[j].ethFee,
                                holder.transferSnaps[i].snapBalance,
                                _winningInfo[j].totalStakedSupply
                            );

                            // or if it happened before a payout
                        } else if (
                            holder.transferSnaps[i].blockNumber <
                            _winningInfo[j].blockNumber
                        ) {
                            // and their next transaction happened after
                            if (
                                holder.transferSnaps[i + 1].blockNumber >
                                _winningInfo[j].blockNumber
                            ) {
                                // give eth accordingly
                                // eth +=
                                //     (_winningInfo[j].ethFee *
                                //         holder.transferSnaps[i].snapBalance) /
                                //     _winningInfo[j].totalStakedSupply;

                                eth += Math.mulDiv(
                                    _winningInfo[j].ethFee,
                                    holder.transferSnaps[i].snapBalance,
                                    _winningInfo[j].totalStakedSupply
                                );
                            }
                        }
                        // if the current loop is not NOT the holder's last tx...
                    } else {
                        // give eth accordingly
                        // eth +=
                        //     (_winningInfo[j].ethFee *
                        //         holder.transferSnaps[i].snapBalance) /
                        //     _winningInfo[j].totalStakedSupply;

                        eth += Math.mulDiv(
                            _winningInfo[j].ethFee,
                            holder.transferSnaps[i].snapBalance,
                            _winningInfo[j].totalStakedSupply
                        );
                    }
                }
            }
            // but if that holder actually only had one transaction
        } else if (holder.transferSnaps.length == 1) {
            // loop through lotto payout history
            for (uint256 k = 0; k < _winningInfo.length - 1; k++) {
                if (enabledOn < _winningInfo[k].blockNumber) {
                    // check to see if they had their coins before payout
                    if (
                        holder.transferSnaps[0].blockNumber <=
                        _winningInfo[k].blockNumber
                    ) {
                        // give eth accordingly
                        // eth +=
                        //     (_winningInfo[k].ethFee *
                        //         holder.transferSnaps[0].snapBalance) /
                        //     _winningInfo[k].totalStakedSupply;

                        eth += Math.mulDiv(
                            _winningInfo[k].ethFee,
                            holder.transferSnaps[0].snapBalance,
                            _winningInfo[k].totalStakedSupply
                        );
                    }
                }
            }
        }

        // return the entire amount of eth they've accumulated yay
        return eth;
    }

    /// @notice calculates how many tokens are to be rewarded
    /// @dev it's sorta an exponential decay function using a half-life- should
    /// end up with ~21,000,000 minted
    /// @param initVal what the first token payout is/was
    /// @param nonce how many lottery rounds have finished
    /// @param halfLife at how many iterations should `price` = `initVal` / 2
    function _calculateMintValue(
        uint256 initVal,
        uint256 nonce,
        uint256 halfLife
    ) private pure returns (uint256) {
        nonce -= 1;
        initVal >>= nonce / halfLife;
        nonce %= halfLife;
        // uint256 price = initVal - (initVal * nonce) / halfLife / 2;
        uint256 price = initVal - Math.mulDiv(initVal, nonce, halfLife / 2);
        return price;
    }
}
