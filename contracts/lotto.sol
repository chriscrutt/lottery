// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./lottoTickets.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Lotto is LottoTickets, Context {
    event BuyTickets(address account, uint256 amount);

    uint256 private _endingBlock;
    uint256 private _pauseBuffer;
    bool private _paid;
    uint256 private _blocksToWait;

    constructor(uint256 blocksToWait_, uint256 pauseBuffer_) {
        _pauseBuffer = pauseBuffer_;
        _blocksToWait = blocksToWait_;
        _endingBlock = block.number + blocksToWait_;
    }

    function endingBlock() public view returns (uint256) {
        return _endingBlock;
    }

    function pauseBuffer() public view returns (uint256) {
        return _pauseBuffer;
    }

    /// @dev starts the lottery timer enabling purchases of ticket bundles.
    /// can't start if one is in progress and the last winner has not been paid.
    /// cannot be from a contract - humans only-ish
    function _start() internal virtual {
        require(
            block.number > _endingBlock + _pauseBuffer,
            "round not over yet"
        );
        require(_paid, "haven't _paid out yet");

        // since a new round is starting, we do not have a winner yet to be paid
        _paid = false;

        // `_endingblock` is the current block + how many blocks we said earlier
        _endingBlock = block.number + _blocksToWait;
    }

    function buyTickets() public payable virtual {
        require(block.number <= _endingBlock, "passed deadline");
        require(msg.value > 0, "gotta pay to play");
        _mintTickets(_msgSender(), msg.value);

        emit BuyTickets(_msgSender(), msg.value);
    }

    /// @notice pulls the winning ticket for all to see yay
    /// @dev `_sortaRandom` is calculated by taking the block hash of the block
    /// we specified to end ticket purchases on plus a buffer. This is difficult
    /// to manipulate and predict. Then we get the remainder of it divided by
    /// tickets purchased that becomes more difficult to predict the more volume
    /// there is(?) That remainder is the winning ticket number.
    /// @return the "random" number, how many tickets created, and the winning
    /// number. This is to create transparency hopefully.
    function _calculateWinningTicket() internal view returns (uint256) {
        uint256 bHash = uint256(blockhash(_endingBlock + _pauseBuffer));
        require(bHash != 0, "wait a few confirmations");

        return bHash % _currentTicket();
    }

    function _payout(address account, uint256 amount) internal virtual {
        require(!_paid, "already paid out");
        require(
            block.number >= _endingBlock + _pauseBuffer,
            "round not over yet"
        );
        _reset();
        payable(account).transfer(amount);
        _paid = true;
    }
}
