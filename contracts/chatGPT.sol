// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./lotto.sol";
import "./lottoDAO.sol";

/**
 * @title MyLottery
 * @dev A simple lottery contract that allows users to enter and win a prize.
 * @notice The contract balance must be at least 1000 before payouts can be made.
 */
contract MyLottery is LottoDAO {
    /**
     * @dev Creates a new instance of the MyLottery contract.
     */
    constructor() Lotto(5) LottoDAO("Lottery Reward Token", "LRT", 2, 10) {
        _addBeneficiary(_msgSender(), 10);
    }

    /**
     * @dev Pays out the contract balance to the winner of the round and restarts the lottery.
     * @notice The contract balance must be at least 1000, the current block greater than the
     * ending block of the current round, and the current round must not have already been paid out
     */
    function payoutAndRestart() public {
        uint256 pot = address(this).balance;

        require(pot >= 1000, "pot has to be >= 1000");

        require(block.number > endingBlock(), "round not over yet");

        require(!paid(), "already paid out");

        _payout(pot);

        startStaking();

        _start();
    }

    /**
     * @dev Returns the current block number.
     * @return The current block number.
     */
    function currentBlock() public view returns (uint256) {
        return block.number;
    }
}
