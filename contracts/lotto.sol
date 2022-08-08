// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./lottoTickets.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Lotto is LottoTickets, Context {
    event Start(uint256 startingBlock, uint256 endingBlock);
    event Payout(uint256 amount, address account);

    uint256 private _endingBlock;
    uint256 private _pauseBuffer;
    bool private _paid;
    uint256 private _blocksToWait;

    constructor(uint256 blocksToWait_, uint256 pauseBuffer_) {
        _endingBlock = block.number;
        _pauseBuffer = pauseBuffer_;
        _paid = true;
        _blocksToWait = blocksToWait_;
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

        emit Start(block.number, _endingBlock);
    }

    function buyTickets() public payable virtual {
        require(block.number <= _endingBlock, "passed deadline");
        require(msg.value > 0, "gotta pay to play");
        _mintTickets(_msgSender(), msg.value);
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

        emit Payout(amount, account);
    }
}
