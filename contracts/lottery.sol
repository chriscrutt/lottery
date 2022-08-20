// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lotto.sol";
import "./ERC80085.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// TODO
/// see cheaper options
/// reorder functions
/// remove unneccessary
///     variables
///     functions
///     visibilities
///     imports (like math)
/// enable staking and withdrawing
/// add comments

contract LottoRewardsToken is ERC80085 {
    // will be the lottery contract

    address private _creator;

    constructor()
        ERC20("Lotto Rewards Token", "LT")
        ERC20Permit("Lotto Rewards Token")
    {
        _creator = _msgSender();
        _mint(_msgSender(), 21000000 * 10**decimals());
    }

    receive() external payable {
        require(_msgSender() == _creator, "non-recoverable funds");
    }

    function startStaking() public {
        _startStaking(_msgSender());
    }
}

contract Lottery is Lotto {
    // will handle each lotto win
    struct WinningInfo {
        address winner;
        uint256 ticketNumber;
        uint256 winningAmount;
        uint256 fees;
        uint256 blockNumber;
        uint256 totalStakedSupply;
    }

    LottoRewardsToken public lottoRewardsToken;

    address payable private _beneficiary;
    uint256 private _invertedFee;
    WinningInfo[] private _winningInfo;

    constructor() payable Lotto(5, 1) {
        require(msg.value >= 2, "need 2 wei initial funding");
        lottoRewardsToken = new LottoRewardsToken();

        _beneficiary = payable(_msgSender());
        _invertedFee = 99;

        uint256 value = msg.value / 2;
        lottoRewardsToken.startStaking();
        _mintTickets(_msgSender(), value);
        _mintTickets(_msgSender(), msg.value - value);
    }

    /// @dev this updates the placeholder winning info for the current nonce and
    /// sets it to... the winning info
    function _logWinningPlayer(
        address account,
        uint256 winnings,
        uint256 fee,
        uint256 stakedSupply,
        uint256 winningTicket
    ) internal {
        _winningInfo.push(
            WinningInfo({
                winner: account,
                ticketNumber: winningTicket,
                winningAmount: winnings,
                fees: fee,
                blockNumber: block.number,
                totalStakedSupply: stakedSupply
            })
        );
    }

    function winningHistory() public view returns (WinningInfo[] memory) {
        return _winningInfo;
    }

    function _payoutAndRestart(
        address account,
        uint256 amount,
        uint256 winningTicket
    ) private {
        uint256 winningAmount = (amount * _invertedFee) / 100;
        _payout(account, winningAmount);
        _beneficiary.transfer(address(this).balance / 2);

        _logWinningPlayer(
            account,
            winningAmount,
            address(this).balance,
            lottoRewardsToken.totalStakedSupply(),
            winningTicket
        );

        payable(lottoRewardsToken).transfer(address(this).balance);

        _start();
    }

    function payoutAndRestart() public payable {
        require(msg.value >= 2, "need 2 wei initial funding");
        uint256 bHash = uint256(blockhash(endingBlock() + pauseBuffer()));
        require(bHash != 0, "wait a few confirmations");
        uint256 winningTicket = bHash % currentTicketId();
        address winner = _findTicketOwner(winningTicket);
        _payoutAndRestart(winner, address(this).balance, winningTicket);
        uint256 tokensLeft = lottoRewardsToken.balanceOf(address(this));

        uint256 value = msg.value / 2;
        _mintTickets(_msgSender(), value);
        _mintTickets(_msgSender(), msg.value - value);

        if (tokensLeft > 0) {
            lottoRewardsToken.transfer(_msgSender(), tokensLeft / 100);
        }
    }

    function _accumulatedEther(address account)
        private
        view
        returns (uint256 eth)
    {
        ERC80085.TokenHolder memory holder = lottoRewardsToken.holderData(
            account
        );
        // handle if length == 0
        uint256 holderLen = holder.transferSnaps.length;
        for (uint256 i = 0; i < holder.transferSnaps.length; ++i) {
            for (uint256 j = 0; j < _winningInfo.length; ++j) {
                if (holder.stakedOnBlock > _winningInfo[j].blockNumber) {
                    continue;
                }
                if (
                    holder.transferSnaps[i].blockNumber ==
                    _winningInfo[j].blockNumber
                ) {
                    eth += Math.mulDiv(
                        _winningInfo[j].fees,
                        holder.transferSnaps[i].snapBalance,
                        _winningInfo[j].totalStakedSupply
                    );
                } else if (
                    holder.transferSnaps[i].blockNumber <
                    _winningInfo[j].blockNumber
                ) {
                    if (
                        i < holderLen - 1 &&
                        holder.transferSnaps[i + 1].blockNumber >
                        _winningInfo[j].blockNumber
                    ) {
                        eth += Math.mulDiv(
                            _winningInfo[j].fees,
                            holder.transferSnaps[i].snapBalance,
                            _winningInfo[j].totalStakedSupply
                        );
                    }
                } else {
                    eth += Math.mulDiv(
                        _winningInfo[j].fees,
                        holder.transferSnaps[i].snapBalance,
                        _winningInfo[j].totalStakedSupply
                    );
                }
            }
        }
    }

    function withdrawFees() public {
        uint256 eth = _accumulatedEther(_msgSender());
        payable(_msgSender()).transfer(
            eth - lottoRewardsToken.holderData(_msgSender()).rewardsWithdrawn
        );
    }
}
