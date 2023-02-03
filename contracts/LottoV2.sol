// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./LottoTicketsV2.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**

TODO

[x] make more gas-efficient
[ ] add ignore to functions mixed up because where they are placed right now makes it flow better
[ ] add NatSpec
[ ] make some internal functions public?


 */

contract BasicLotto is LottoTicketsV2, Context, Ownable {
    uint256 private _minPot;

    uint256 private _lottoLength;

    uint256 private _endingBlock;

    event Payout(address to, uint256 amount);

    constructor(uint256 minPot_, uint256 lottoLength_) {
        require(minPot_ > 0 || lottoLength_ > 0, "1 arg must be > 0");
        _minPot = minPot_;
        _lottoLength = lottoLength_;
        _endingBlock = block.number + lottoLength_;
    }

    function _potMinimum() internal virtual returns (uint256) {
        return _minPot;
    }

    function _lotteryLength() internal virtual returns (uint256) {
        return _lottoLength;
    }

    function _lotteryEndsAfterBlock() internal virtual returns (uint256) {
        return _endingBlock;
    }

    function buyTickets() public payable virtual {
        require(block.number <= _endingBlock || address(this).balance < _minPot, "lottery is over");
        require(msg.value > 0, "gotta pay to play");
        _mintTickets(_msgSender(), msg.value);
    }

    function _calculateWinningTicket() private view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(blockhash(_endingBlock + 1), block.prevrandao, _circulatingTickets()))) %
            _circulatingTickets();
    }

    function _payout() internal virtual {
        uint256 winningTicket = _calculateWinningTicket();
        address winner = _findTicketOwner(winningTicket);
        _reset();
        _endingBlock = block.number + _lottoLength;
        uint256 amount = address(this).balance;
        payable(winner).transfer(amount);
        emit Payout(winner, amount);
    }

    function payout() public virtual onlyOwner {
        require(block.number > _endingBlock, "lottery time isn't up");
        require(address(this).balance >= _minPot, "minimum pot hasn't been reached");
        _payout();
    }
}
