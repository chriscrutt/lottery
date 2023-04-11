// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./LottoTicketsV2.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**

TODO

[x] make more gas-efficient
[x] add ignore to functions mixed up because where they are placed right now makes it flow better
[x] add NatSpec
[x] make some internal functions public?
[-] should lottery end on block or block after
[x] think about openzeppelin's Timer contract - nope


 */

contract BasicLotto is LottoTicketsV2, Context, ReentrancyGuard {
    // round info, easy
    struct Round {
        address winner;
        uint256 pot;
    }

    // list of all the rounds played
    Round[] private _rounds;

    // minimum pot for lottery to end
    uint256 private _minPot;

    // length of each lottery
    uint256 private _roundLength;

    uint256 private _beforeDraw;

    uint256 private _afterDraw;

    // what the ending block will be
    uint64 private _lottoTimer;

    // on lottery payout
    event Payout(address to, uint256 amount);

    /**
     * @notice sets up lottery and starts it!
     * @param minPot_ minimum pot for lottery to end
     * @param lottoLength_ minimum block length for lottery to end
     * @param securityBeforeDraw_ blocks to wait before drawing for security
     * @param securityAfterDraw_ blocks to wait before payout for security
     */
    constructor(uint256 minPot_, uint256 lottoLength_, uint256 securityBeforeDraw_, uint256 securityAfterDraw_) {
        require(minPot_ > 0, "need garunteed participant");
        _minPot = minPot_;
        _roundLength = lottoLength_;
        _beforeDraw = securityBeforeDraw_;
        _afterDraw = securityAfterDraw_;
        // _endingBlock = block.number + lottoLength_;
        _lottoTimer = uint64(block.number + lottoLength_);
    }

    /**
     * @notice buy tickets
     */
    function buyTickets() public payable virtual returns (bool) {
        require(block.number <= _lottoTimer || address(this).balance <= _minPot, "lottery is over");
        require(msg.value > 0, "gotta pay to play");
        _mintTickets(_msgSender(), msg.value);
        return true;
    }

    /**
     * @notice see blocks to go by before drawing winner for security reasons
     */
    function payoutAvailableOnBlock() public view returns (uint256) {
        return _lottoTimer + _beforeDraw + _afterDraw;
    }

    /**
     * @notice get all lottery winners and pot
     */
    function lotteryLookup(uint256 id) public view returns (Round memory) {
        return _rounds[id];
    }

    /**
     * @notice minimum pot
     */
    function minimumPot() public view virtual returns (uint256) {
        return _minPot;
    }

    /**
     * @notice what block number will the lotto finish on
     */
    function lottoDeadline() public view virtual returns (uint64) {
        return _lottoTimer;
    }

    /**
     * @notice current block for player easy access
     */
    function currentBlock() public view virtual returns (uint256) {
        return block.number;
    }

    function payout() public virtual nonReentrant returns (bool) {
        uint256 balance = address(this).balance;
        require(balance >= _minPot, "minimum pot hasn't been reached");
        _payout(balance);
        return true;
    }

    /**
     * @dev calculates winning ticket, finds the ticket owner, resets lottery, pays out winner
     * @param amount to be paid out to winner
     */
    function _payout(uint256 amount) internal virtual {
        uint256 winningTicket = _calculateWinningTicket();
        address winner = _findTicketOwner(winningTicket);
        _reset();
        _lottoTimer = uint64(block.number + _roundLength);
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
    function _calculateWinningTicket() internal view returns (uint256) {
        require(_lottoTimer + _beforeDraw + _afterDraw < block.number, "wait for finality");
        return
            uint256(keccak256(abi.encodePacked(blockhash(_lottoTimer + _beforeDraw), address(this).balance))) %
            address(this).balance;
    }
}
