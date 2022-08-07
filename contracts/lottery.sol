// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./lottoRewardsToken.sol";
import "./lottoTickets.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Lottery is LottoTickets, Context {
    uint256 private _endingBlock;
    uint256 private _pauseBuffer;
    bool private _paid;
    uint256 private _blocksToWait;

    constructor() {
        _endingBlock = block.number;
        _pauseBuffer = 1;
        _paid = true;
        _blocksToWait = 5;
    }

    /// @dev starts the lottery timer enabling purchases of ticket bundles.
    /// can't start if one is in progress and the last winner has not been paid.
    /// cannot be from a contract - humans only-ish
    function _start() internal {
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

    function received() external payable {
        buyTickets();
    }

    function buyTickets() public payable {
        require(block.number <= _endingBlock, "passed deadline");
        require(msg.value > 0, "gotta pay to play");
        _buyTickets(_msgSender(), msg.value);
    }

    function _payout(address account, uint256 amount) internal {
        require(!_paid, "already paid out");
        require(
            block.number >= _endingBlock + _pauseBuffer,
            "round not over yet"
        );
        _reset();
        _paid = true;
        payable(account).transfer(amount);
    }
}
