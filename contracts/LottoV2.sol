// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ILottoV2.sol";
import "./LottoTicketsV2.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Timers.sol";

/**

TODO

[x] make more gas-efficient
[x] add ignore to functions mixed up because where they are placed right now makes it flow better
[x] add NatSpec
[x] make some internal functions public?
[-] should lottery end on block or block after
[x] think about openzeppelin's Timer contract - nope


 */

contract Lottery is ILottery, LottoTicketsV2, Context, ReentrancyGuard {
    using Timers for Timers.BlockNumber;

    // list of all the rounds played
    Round[] private _rounds;

    // minimum pot for lottery to end
    uint256 private _minPot;

    // length of each lottery
    uint256 private _roundLength;

    uint256 private _beforeDraw;

    uint256 private _afterDraw;

    // what the ending block will be
    Timers.BlockNumber private _lottoTimer;

    /**
     * @notice sets up lottery and starts it!
     * @param minPot_ minimum pot for lottery to end
     * @param lottoLength_ minimum block length for lottery to end
     * @param securityBeforeDraw_ blocks to wait before drawing for security
     * @param securityAfterDraw_ blocks to wait before payout for security
     */
    constructor(
        uint256 minPot_,
        uint256 lottoLength_,
        uint256 securityBeforeDraw_,
        uint256 securityAfterDraw_
    ) {
        require(minPot_ > 0, "need garunteed participant");
        _minPot = minPot_;
        _roundLength = lottoLength_;
        _beforeDraw = securityBeforeDraw_;
        _afterDraw = securityAfterDraw_;
        // _endingBlock = block.number + lottoLength_;
        _lottoTimer.setDeadline(uint64(block.number + lottoLength_));
    }

    /**
     * @notice buy tickets
     */
    function buyTickets() public payable virtual override nonReentrant returns (bool) {
        require(_lottoTimer.isPending() || address(this).balance <= _minPot, "lottery is over");
        require(msg.value > 0, "gotta pay to play");
        _mintTickets(_msgSender(), msg.value);
        return true;
    }

    function payout() public virtual override nonReentrant returns (bool) {
        uint256 balance = address(this).balance;
        require(balance >= _minPot, "minimum pot hasn't been reached");
        _payout(balance);
        return true;
    }

    /**
     * @notice see blocks to go by before drawing winner for security reasons
     */
    function payoutAvailableOnBlock() public view virtual override returns (uint256) {
        return _lottoTimer.getDeadline() + _beforeDraw + _afterDraw;
    }

    /**
     * @notice get all lottery winners and pot
     */
    function lotteryLookup(uint256 id) public view virtual override returns (Round memory) {
        return _rounds[id];
    }

    /**
     * @notice minimum pot
     */
    function minimumPot() public view virtual override returns (uint256) {
        return _minPot;
    }

    /**
     * @notice what block number will the lotto finish on
     */
    function lottoDeadline() public view virtual override returns (uint256) {
        return _lottoTimer.getDeadline();
    }

    /**
     * @notice current block for player easy access
     */
    function currentBlock() public view virtual override returns (uint256) {
        return block.number;
    }

    function roundLength() public view virtual override returns (uint256) {
        return _roundLength;
    }

    function _updateLottoTimer(uint64 newTime) internal virtual {
        _lottoTimer.setDeadline(newTime);
    }

    /**
     * @dev calculates winning ticket, finds the ticket owner, resets lottery, pays out winner
     * @param amount to be paid out to winner
     */
    function _payout(uint256 amount) internal virtual {
        uint256 winningTicket = _calculateWinningTicket();
        address winner = _findTicketOwner(winningTicket);
        _reset();
        // _logRound(winner, amount); instead below
        _rounds.push(Round(winner, amount));
        (bool sent, ) = payable(winner).call{ value: amount }("");
        require(sent, "Failed to send Ether");
        // payable(winner).transfer(amount);
        emit Payout(winner, amount);
    }

    /**
     * @dev calculates winning ticket using hashing blockhash, prevrandao, and number of tickets
     */
    function _calculateWinningTicket() internal view virtual returns (uint256) {
        require(
            _lottoTimer.getDeadline() + _beforeDraw + _afterDraw < block.number,
            "wait for finality"
        );
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(_lottoTimer.getDeadline() + _beforeDraw),
                        address(this).balance
                    )
                )
            ) % address(this).balance;
    }
}
