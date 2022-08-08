// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./lotto.sol";
import "./ERC80085.sol";

contract LottoRewardsToken is ERC80085 {
    // will be the lottery contract
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor()
        ERC20("Lotto Rewards Token", "LT")
        ERC20Permit("Lotto Rewards Token")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, _msgSender());
        _mint(address(this), 21000000 * decimals());
    }
}

abstract contract Lottery is Lotto {
    LottoRewardsToken public lottoRewardsToken;

    address payable private _beneficiary;
    uint256 private _invertedFee;

    constructor() {
        lottoRewardsToken = new LottoRewardsToken();

        _beneficiary = payable(address(0));
        _invertedFee = 99;
    }

    function _payoutAndRestart(address account, uint256 amount) private {
        uint256 winningAmount = (amount * _invertedFee) / 100;
        _payout(account, winningAmount);
        _beneficiary.transfer(address(this).balance / 2);
        payable(lottoRewardsToken).transfer(address(this).balance);
        _start();
    }

    function _calculateMintValue(uint256 tokensLeft)
        private
        pure
        returns (uint256)
    {
        return tokensLeft / 100;
    }

    function payoutAndRestart() public {
        uint256 winningTicket = _calculateWinningInfo();
        address winner = _findTicketOwner(winningTicket);
        _payoutAndRestart(winner, address(this).balance);

        uint256 tokensLeft = lottoRewardsToken.balanceOf(
            address(lottoRewardsToken)
        );

        if (tokensLeft > 0) {
            lottoRewardsToken.transfer(
                _msgSender(),
                _calculateMintValue(tokensLeft)
            );
        }
    }
}
