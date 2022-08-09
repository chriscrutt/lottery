// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./lotto.sol";
import "./ERC80085.sol";

// will handle each lotto win
struct WinningInfo {
    address winner;
    uint256 ticketNumber;
    uint256 winningAmount;
    uint256 blockNumber;
    uint256 totalStakedSupply;
}

contract LottoRewardsToken is ERC80085 {
    // will be the lottery contract

    constructor()
        ERC20("Lotto Rewards Token", "LT")
        ERC20Permit("Lotto Rewards Token")
    {
        _mint(_msgSender(), 21000000 * 10**decimals());
    }

    function startStaking() public {
        _startStaking(_msgSender());
    }

    /// @notice withdraw ethereum fees as a token holder
    /// @dev calculates amount of eth available to withdraw here- maybe change?
    /// @param account replacing tx.origin/msg.sender sorry
    // function withdraw(address account) external {
    //     TokenHolder memory accountData = holderData(account);
    //     require(accountData.stakedOnBlock > 0, "rewards aren't enabled");

    //     uint256 etherEarned = _accumulatedEther(
    //         account,
    //         accountData.stakingInfo.startedOnBlock
    //     );

    //     require(
    //         accountData.rewardsWithdrawn < etherEarned,
    //         "withdraws up-to-date"
    //     );
    //     uint256 ethToSend = etherEarned - accountData.rewardsWithdrawn;
    //     _updateWithdrawals(account, ethToSend);
    //     _transferWinnings(payable(account), ethToSend);
    // }
}

contract Lottery is Lotto {
    LottoRewardsToken public lottoRewardsToken;

    address payable private _beneficiary;
    uint256 private _invertedFee;
    WinningInfo[] private _winningInfo;

    constructor() payable Lotto(5, 1) {
        lottoRewardsToken = new LottoRewardsToken();

        _beneficiary = payable(address(0));
        _invertedFee = 99;

        buyTickets();
    }

    /// @dev this updates the placeholder winning info for the current nonce and
    /// sets it to... the winning info
    function _logWinningPlayer(
        address account,
        uint256 winnings,
        uint256 stakedSupply
    ) internal {
        // pulls random tx hash, tickets bought, and winning ticket number.
        uint256 number = _calculateWinningTicket();

        _winningInfo.push(
            WinningInfo({
                winner: account,
                ticketNumber: number,
                winningAmount: winnings,
                blockNumber: block.number,
                totalStakedSupply: stakedSupply
            })
        );
    }

    function _payoutAndRestart(address account, uint256 amount) private {
        uint256 winningAmount = (amount * _invertedFee) / 100;
        _payout(account, winningAmount);
        _beneficiary.transfer(address(this).balance / 2);
        payable(lottoRewardsToken).transfer(address(this).balance);

        _logWinningPlayer(
            account,
            winningAmount,
            lottoRewardsToken.totalStakedSupply()
        );

        _start();
    }

    function payoutAndRestart() public {
        uint256 winningTicket = _calculateWinningTicket();
        address winner = _findTicketOwner(winningTicket);
        _payoutAndRestart(winner, address(this).balance);
        uint256 tokensLeft = lottoRewardsToken.balanceOf(address(this));

        if (tokensLeft > 0) {
            lottoRewardsToken.transfer(_msgSender(), tokensLeft / 100);
        }
    }

    function _accumulatedEther(
        address account,
        uint256 enabledOn,
        WinningInfo[] memory winningInfo
    ) private view returns (uint256 eth) {
        TokenHolder memory holder = holderData(account);
        if (holder.transferSnaps.length > 1) {
            for (uint256 i = 0; i < holder.transferSnaps.length; ++i) {
                for (uint256 j = 0; j < _winningInfo.length; ++j) {
                    if (enabledOn < _winningInfo[j].blockNumber) {
                        continue;
                    }
                }
            }
        }
    }
}
