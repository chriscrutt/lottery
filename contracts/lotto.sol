// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;
import "./lottoTickets.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
/// is setting `bHash` worth it?

/**
 * @title Lotto
 * @dev Lotto contract that allows users to purchase tickets and participate in a lottery.
 * The contract has a fixed duration, after which a winner is chosen and the contract balance
 * is paid out to the winner.
 */

contract Lotto is LottoTickets, Context {
    // will handle each lotto win
    struct WinningInfo {
        address winner;
        uint256 winningAmount;
    }

    // the block the lottery will be ending on
    uint256 private _endingBlock;

    // has the winner been paid out?
    bool private _paid;

    // how long the lottery should last
    uint256 private _blocksToWait;

    address private _lastWinner;

    WinningInfo[] private _winningHistory;

    event Payout(address account, uint256 amount);

    /// @notice sets up lottery configuration
    /// @dev starts lottery technically immediately except `_paid` is false not true
    /// @param blocksToWait_ how long the lotto should last
    constructor(uint256 blocksToWait_) {
        _blocksToWait = blocksToWait_;
        _endingBlock = block.number + blocksToWait_;
        // _paid = true;
    }

    /// @notice buys tickets
    /// @dev where 1 = 1 wei and mints to msg.sender
    function buyTickets() public payable virtual {
        require(block.number <= _endingBlock, "passed deadline");
        require(msg.value > 0, "gotta pay to play");
        _mintTickets(_msgSender(), msg.value);
    }

    // /**
    //  * @dev Pays out the contract balance to the winner of the current round.
    //  */
    // function payout() public virtual {
    //     // Get the contract balance
    //     uint256 pot = address(this).balance;

    //     // Revert if the contract balance is less than 1000
    //     require(pot >= 1000, "pot has to be >= 1000");

    //     // Revert if the current block number is not greater than the ending block number
    //     require(block.number > _endingBlock, "round not over yet");

    //     // Revert if the round has already been paid out
    //     require(!_paid, "already paid out");

    //     // Pay out the contract balance to the winner of the current round
    //     _payout(pot);
    // }

    function addTime() public {
        _addTime();
    }

    /// @notice the block the lottery ends on
    function endingBlock() public view returns (uint256) {
        return _endingBlock;
    }

    function paid() public view returns (bool) {
        return _paid;
    }

    function lastWinner() public view returns (address) {
        return _lastWinner;
    }

    /// @dev starts the lottery timer enabling purchases of ticket bundles.
    /// can't start if one is in progress and the last winner has not been paid.
    /// cannot be from a contract - humans only-ish
    function _start() internal virtual {
        require(block.number > _endingBlock, "round not over yet");
        require(_paid, "haven't _paid out yet");

        // since a new round is starting, we do not have a winner yet to be paid
        _paid = false;

        // `_endingblock` is the current block + how many blocks we said earlier
        _endingBlock = block.number + _blocksToWait;
    }

    /// @dev this updates the placeholder winning info for the current nonce and
    /// sets it to... the winning info
    function _logWinningPlayer(
        address account,
        uint256 winnings
    ) internal virtual {
        _winningHistory.push(
            WinningInfo({ winner: account, winningAmount: winnings })
        );
    }

    /**
     * @dev Pays out the specified amount to the winner of the current round.
     * @param amount The amount to be paid out.
     */
    function _payout(uint256 amount) internal virtual {
        // Calculate the winning ticket number
        uint256 winningTicket = _calculateWinningTicket();

        // Get the owner of the winning ticket
        address roundWinner = findTicketOwner(winningTicket);

        // Store the winner in the contract storage
        _lastWinner = roundWinner;

        // Reset the contract state
        _reset();

        // Mark the round as paid out
        _paid = true;

        // Log the winning player and payout amount
        _logWinningPlayer(roundWinner, amount);

        // Transfer the payout amount to the winner
        payable(roundWinner).transfer(amount);

        // Emit the Payout event
        emit Payout(roundWinner, amount);
    }

    /**
     * @dev Adds time to the current round.
     */
    function _addTime() internal virtual {
        require(block.number > _endingBlock, "round not over yet");
        require(!_paid, "already paid out");
        require(currentTicketId() < 1000, "only add time if < 1000 bets");
        _endingBlock = block.number + _blocksToWait;
    }

    /**
     * @dev Calculates the winning ticket number based on the ending block hash, current ticket ID,
     * block timestamp, block base fee, and remaining gas.
     * @return winningTicket The winning ticket number.
     *
     * The winning ticket number is calculated by hashing the packed encoding of the following:
     * - The block hash of the block with the specified `_endingBlock` number.
     * - The current ticket ID, which is the total number of tickets that have been sold so far.
     * - The block timestamp of the current block.
     * - The block base fee of the current block.
     * - The remaining gas available in the current block.
     *
     * The resulting hash is then converted to a uint256 and reduced modulo the current ticket ID
     * to obtain a number in the range [0, current ticket ID).
     */
    function _calculateWinningTicket()
        internal
        view
        virtual
        returns (uint256 winningTicket)
    {
        // Get the block hash for the ending block
        bytes32 bHash = blockhash(_endingBlock);

        // Revert if the block hash is 0
        require(bHash != 0, "wait a few confirmations");

        // Hash the packed encoding of the block hash, current ticket ID, block timestamp, block
        // base fee, and remaining gas
        winningTicket =
            uint256(
                keccak256(
                    abi.encodePacked(
                        bHash,
                        currentTicketId(),
                        block.timestamp, // solhint-disable-line not-rely-on-time
                        block.basefee,
                        gasleft()
                    )
                )
            ) %
            currentTicketId();
    }
}
