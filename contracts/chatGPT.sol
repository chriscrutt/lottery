// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// import "./lottoGratuity.sol";
import "./lotto.sol";
import "./lottoDAO.sol";

contract MyLottery is LottoDAO {
    constructor() Lotto(5) LottoDAO("Lottery Reward Token", "LRT", 2, 10) {
        _addBeneficiary(_msgSender(), 10);
    }

    function currentBlock() public view returns (uint256) {
        return block.number;
    }

    /**
     * @dev Pays out the contract balance to the winner of the current round.
     */
    function payoutAndRestart() public {
        // Get the contract balance
        uint256 pot = address(this).balance;

        // Revert if the contract balance is less than 1000
        require(pot >= 1000, "pot has to be >= 1000");

        // Revert if the current block number is not greater than the ending block number
        require(block.number > endingBlock(), "round not over yet");

        // Revert if the round has already been paid out
        require(!paid(), "already paid out");

        // Pay out the contract balance to the winner of the current round
        _payout(pot);

        _start();
    }
}
