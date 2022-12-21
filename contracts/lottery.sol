// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lotto.sol";
import "./ERC80085.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// TODO
/// see cheaper options
/// reorder functions
/// remove unneccessary
///     variables
///     functions
///     visibilities
///     imports (like math)
/// add comments
/// subtract before sending funds
/// see if loop runs out of gas
/// make sure ALL eth gets sent
/// unchecked has a very minimal effect
///     consider only using it for loops/recursion
/// is setting `winningAmount` worth it?
/// is setting `winningTicket` worth it?
/// don't have to check for / 0 because tokens are staked at contract creation

contract LottoRewardsToken is ERC80085, Ownable {
    // will be the lottery contract

    constructor()
        ERC20("Lotto Rewards Token", "LT")
        ERC20Permit("Lotto Rewards Token")
    {} // solhint-disable-line no-empty-blocks

    receive() external payable {}

    function startStaking() public {
        _startStaking(_msgSender());
    }

    function startStaking(address account) public onlyOwner {
        _startStaking(account);
    }

    function transferEth(address to, uint256 amount) public onlyOwner {
        _transferEth(to, amount);
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

    constructor() payable Lotto(5) {
        require(msg.value >= 200, "need 200 wei initial funding");
        lottoRewardsToken = new LottoRewardsToken();

        _beneficiary = payable(_msgSender());
        _invertedFee = 99;

        unchecked {
            uint256 value = msg.value / 2;
            _mintTickets(_msgSender(), value);
            _mintTickets(_msgSender(), msg.value - value);
        }
        // mint 1 to person
        lottoRewardsToken.startStaking(_msgSender());
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

    function startStaking() public {
        lottoRewardsToken.startStaking(_msgSender());
    }

    function winningHistory() public view returns (WinningInfo[] memory) {
        return _winningInfo;
    }

    function _payoutAndRestart(
        address account,
        uint256 amount,
        uint256 initialFunded,
        uint256 winningTicket
    ) private {
        unchecked {
            uint256 winningAmount = (amount * _invertedFee) / 100;
            _payout(account, winningAmount);
            _beneficiary.transfer((address(this).balance - initialFunded) / 2);

            _logWinningPlayer(
                account,
                winningAmount,
                address(this).balance,
                lottoRewardsToken.totalStakedSupply(),
                winningTicket
            );
        }

        payable(lottoRewardsToken).transfer(
            address(this).balance - initialFunded
        );

        _start();
    }

    function payoutAndRestart() public payable {
        require(msg.value >= 200, "need 200 wei initial funding");
        uint256 bHash = uint256(blockhash(endingBlock()));
        require(bHash != 0, "wait a few confirmations");
        uint256 winningTicket = bHash % currentTicketId();
        address winner = _findTicketOwner(winningTicket);

        unchecked {
            uint256 tokensLeft = lottoRewardsToken.balanceOf(address(this));
            if (tokensLeft > 99) {
                lottoRewardsToken.transfer(_msgSender(), tokensLeft / 100);
            } else if (tokensLeft > 0) {
                lottoRewardsToken.transfer(_msgSender(), 1);
            }
        }

        _payoutAndRestart(
            winner,
            address(this).balance,
            msg.value,
            winningTicket
        );

        unchecked {
            uint256 value = msg.value / 2;
            _mintTickets(_msgSender(), value);
            _mintTickets(_msgSender(), msg.value - value);
        }
    }

    function _accumulatedEther(address account)
        public
        view
        returns (uint256 eth)
    {
        ERC80085.TokenHolder memory holder = lottoRewardsToken.holderData(
            account
        );
        // handle if length == 0
        uint256 holderLen = holder.transferSnaps.length;
        uint256 winningLen = _winningInfo.length;

        unchecked {
            for (uint256 i = 0; i < holderLen; ++i) {
                for (uint256 j = 0; j < winningLen; ++j) {
                    if (holder.stakedOnBlock > _winningInfo[j].blockNumber) {
                        continue;
                    }
                    if (
                        holder.transferSnaps[i].blockNumber ==
                        _winningInfo[j].blockNumber
                    ) {
                        eth +=
                            (_winningInfo[j].fees *
                                holder.transferSnaps[i].snapBalance) /
                            _winningInfo[j].totalStakedSupply;
                    } else if (
                        holder.transferSnaps[i].blockNumber <
                        _winningInfo[j].blockNumber
                    ) {
                        if (
                            i < holderLen - 1 &&
                            holder.transferSnaps[i + 1].blockNumber >
                            _winningInfo[j].blockNumber
                        ) {
                            eth +=
                                (_winningInfo[j].fees *
                                    holder.transferSnaps[i].snapBalance) /
                                _winningInfo[j].totalStakedSupply;
                        }
                    } else {
                        eth +=
                            (_winningInfo[j].fees *
                                holder.transferSnaps[i].snapBalance) /
                            _winningInfo[j].totalStakedSupply;
                    }
                }
            }
        }
    }

    function withdrawFees() public {
        address account = _msgSender();
        unchecked {
            lottoRewardsToken.transferEth(
                account,
                _accumulatedEther(account) -
                    lottoRewardsToken.holderData(account).rewardsWithdrawn
            );
        }
    }
}