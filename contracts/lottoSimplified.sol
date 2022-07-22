// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title A lottery contract
/// @author Dr. Doofenshmirtz
/// @notice Buy tickets with a garunteed winner every ____ blocks
/// @dev A simple lottery contract with three steps:
/// 1. Start the lotto
/// 2. Buy tickets
/// 3. Pay the winner
/// TODO
/// [x] The lotto can be started by anyone but only one may run at the same time
/// [x] Interaction must not be through other smart contracts... no cheating!
///     [x] start
///     [x] buy tickets
///     [x] payout function
/// [ ] Also should buffer time be lengthened/shortened/removed? What effect
///     would it have on security?
/// [x] Need to include a reset function that deletes everything in order for
///     the lotto to start over
///     [n] Can i reset an entire map or make an array of maps and just set that
///         array = []
/// [x] Need to add erc20 token
/// [ ] order functions
/// [X] payout function
/// [X] Need to add percentage fee for me to make money
/// [X] Need to add percentage fee for token holders to make money
/// [X] Clean up comments
/// [x] separate contract for people taking fees
///     [x] erc20 token balance = % of the pot they can withdraw
///     [x] if they hold the token
/// [x] make a public version of findTicketOwner - maybe on other file
contract LottoTickets {
    // will handle the amount of tickets someone purchases
    struct TicketBundle {
        uint256 end;
        address player;
    }

    // will handle each lotto win
    struct WinningInfo {
        address winner;
        uint256 ticketNumber;
        uint256 winningAmount;
        uint256 blockNumber;
        uint256 totalSupply;
        uint256 totalStakedSupply;
        uint256 ethFee;
    }

    // infinity or close to it haha
    uint256 private constant _INFINITY = 2**256 - 1;
    // when lottery ends
    uint256 public endingBlock;
    // has the winner been paid this round
    bool public paid;
    // how many blocks before we pause ticket buys
    uint16 public blocksToWait;
    // how many blocks to pause ticket buys before drawing
    uint16 public pauseBuffer;
    // what is the next ticket number to be purchased
    uint256 public currentTicketId;
    // lotto nonce
    uint256 public lottoNonce;
    // starting point for token mint rewards
    uint256 public initialTokenReward;
    // array to look at past history of winners
    WinningInfo[] internal _winningInfo;

    // handles ticket purchases & key is the starting ticket
    mapping(uint256 => TicketBundle) private _ticketBundles;

    // log the starting ticket of each purchase & can use to loop _ticketBundles
    uint256[] private _bundleFirstTicketId;

    // when payout occurs let 'em know the winner, ticket number, and amount won
    event Payout(address winner, uint256 id, uint256 value);

    // Person who sent the transaction must be the creator of the transaction
    modifier notFromContract() {
        require(msg.sender == tx.origin, "no smart contracts allowed!");
        _;
    }

    /// @dev set `_blocksToWait` and `_pauseBuffer`. also because withdrawing
    /// by erc20 holders requires their last withdraw be before the current
    /// `lottoNonce`, and their starting value is 0, lottoNonce must start at 1.
    /// thus, we must do `_infoPush` twice. First to initiate array and second
    /// to create placeholder values for _winningInfo[1]
    constructor() {
        endingBlock = block.number;
        paid = true;
        blocksToWait = 5;
        pauseBuffer = 1;
        currentTicketId = 0;
        lottoNonce = 1;
        initialTokenReward = 300000 * 10**18;
        _infoPush(address(0), _INFINITY, 0, 0, _INFINITY, _INFINITY, 0);
        _infoPush(address(0), _INFINITY, 0, 0, _INFINITY, _INFINITY, 0);
    }

    /// @dev we want to be able to receive money but don't do anything right now
    receive() external payable {}

    /// @notice purchase a ticket
    /// @dev one ticket = one wei. Tickets must be bought before the set
    /// deadline block is reached. Must not be called from a contract
    function buyTickets() external payable notFromContract {
        require(block.number <= endingBlock, "passed deadline");
        require(msg.value > 0, "gotta pay to play");
        _buyTickets(msg.sender, msg.value);
    }

    /// @notice search through historical winners data by round number
    /// @param round the... round... number... to look up
    function searchWinnerByRound(uint256 round)
        external
        view
        returns (WinningInfo memory)
    {
        return _winningInfo[round];
    }

    /// @return what's the current block?
    function currentBlock() external view returns (uint256) {
        return block.number;
    }

    /// @notice looks up bundle info by bundle number (1st bundle, 2nd, etc)
    /// @dev best for loops and can look up all the bundles people have bought
    /// @param bundleNumber specifies which bundle (sorted by first bought)
    /// @return the ID/key for each bundle A.K.A the first ticket in each bundle
    function bundleInfoByNumber(uint256 bundleNumber)
        external
        view
        returns (uint256)
    {
        return _bundleFirstTicketId[bundleNumber];
    }

    /// @notice looks at ticket bundle info via first ticket bought in bundle
    /// @dev use the starting ticket IDs logged in the `_bundleFirstTicketId`
    /// array as a key to find the bundle you're looking for.
    /// @param bundleFirstTicket the first ticket ID in the bundle
    /// @return the `end` ticket number as well as player's address (the struct)
    function bundleInfoByTicket(uint256 bundleFirstTicket)
        external
        view
        returns (TicketBundle memory)
    {
        return _ticketBundles[bundleFirstTicket];
    }

    /// @notice finds winner's address after getting winning number
    /// @return winner's address
    function winningPlayer() external view returns (WinningInfo memory) {
        return _winningInfo[lottoNonce - 1];
    }

    // /// @return the entire history of all winnings wow
    // function winningHistory() external view returns (WinningInfo[] memory) {
    //     return _winningInfo;
    // }

    /// @dev starts the lottery timer enabling purchases of ticket bundles.
    /// can't start if one is in progress and the last winner has not been paid.
    /// cannot be from a contract - humans only-ish
    function start() public virtual notFromContract {
        require(block.number > endingBlock + pauseBuffer, "round not over yet");
        require(paid, "haven't _paid out yet");

        // since a new round is starting, we do not have a winner yet to be paid
        paid = false;
        // `_endingblock` is the current block + how many blocks we said earlier
        endingBlock = block.number + blocksToWait;

        // give a token??
    }

    /// @notice finds a ticket's owner
    /// @param ticketId is the ticket we wish to find who's it is
    /// @return the address of the ticket owner!
    function findTicketOwner(uint256 ticketId) public view returns (address) {
        // goes through the array of logged bundles
        for (uint256 i = 0; i < _bundleFirstTicketId.length; i++) {
            // if the bundle's starting ticket number is less than `ticketId`
            if (_bundleFirstTicketId[i] <= ticketId) {
                // and the bundle's ending ticket number is more than `ticketId`
                if (_ticketBundles[_bundleFirstTicketId[i]].end >= ticketId) {
                    // return the address of the player who's bundle it is!
                    return _ticketBundles[_bundleFirstTicketId[i]].player;
                }
            }
        }
        return address(0);
    }

    /// @dev this updates the placeholder winning info for the current nonce and
    /// sets it to... the winning info
    function _logWinningPlayer(
        uint256 winnings,
        uint256 supply,
        uint256 stakedSupply,
        uint256 fee
    ) internal returns (WinningInfo memory) {
        require(block.number > endingBlock, "round not over yet");

        require(
            blockhash(endingBlock + pauseBuffer) != 0,
            "wait a few confirmations"
        );

        // pulls random tx hash, tickets bought, and winning ticket number.
        uint256[3] memory numbers = _calculateWinningInfo();

        // makes sure the allotted time has passed to get winning ticket.
        require(numbers[0] != 0, "wait a few confirmations");

        _winningInfo[lottoNonce] = WinningInfo({
            winner: findTicketOwner(numbers[2]),
            ticketNumber: numbers[2],
            winningAmount: winnings,
            blockNumber: block.number,
            totalStakedSupply: stakedSupply,
            totalSupply: supply,
            ethFee: fee
        });

        return _winningInfo[lottoNonce];
    }

    /// @notice sets everything back to initial state
    /// @dev I wish there was a way to delete/restart a map but there isn't so
    /// instead we loop through all the first tickets for each bundle in that
    /// array we made and manually delete them. Then empty the array. Resetting
    /// allows for a new round to be started and for old lottery numbers to not
    /// be grandfathered in next round.
    function _reset() internal {
        endingBlock = block.number;

        currentTicketId = 0;

        _infoPush(address(0), _INFINITY, 0, _INFINITY, _INFINITY, _INFINITY, 0);

        for (uint256 i = 0; i < _bundleFirstTicketId.length; i++) {
            delete _ticketBundles[_bundleFirstTicketId[i]];
        }

        delete _bundleFirstTicketId;

        paid = true;
    }

    /// @notice resets everything and pays out winner.
    /// @dev logs winner to `WinnerInfo` for posterity yay. Lol also relies on
    /// `_logWinningPlayer` being called from an external contract or it'll just
    /// use default values. Reset function is explained further below
    function _payout() internal virtual {
        _reset();

        WinningInfo memory winnerInfo = _winningInfo[lottoNonce];

        payable(winnerInfo.winner).transfer(winnerInfo.winningAmount);
        emit Payout(
            winnerInfo.winner,
            winnerInfo.ticketNumber,
            winnerInfo.winningAmount
        );

        lottoNonce++;
    }

    /// @dev pushes the winner, their ticket number, and amount won to the
    /// historical list of all the other winning data `_winningInfo`
    /// @param winner lotto winner
    /// @param ticNum number of the ticket that won
    /// @param amount amount in the pot that was won
    function _infoPush(
        address winner,
        uint256 ticNum,
        uint256 amount,
        uint256 time,
        uint256 tokenSupply,
        uint256 stakedTokenSupply,
        uint256 feeEth
    ) private {
        _winningInfo.push(
            WinningInfo({
                winner: winner,
                ticketNumber: ticNum,
                winningAmount: amount,
                blockNumber: time,
                totalSupply: tokenSupply,
                totalStakedSupply: stakedTokenSupply,
                ethFee: feeEth
            })
        );
    }

    /// @notice updates amount of tickets purchased and by who
    /// @param to the wallet tickets are to be bought for
    /// @param amount the wallet tickets are to be bought for
    function _buyTickets(address to, uint256 amount) private {
        // using `_currentTicketId` as key to look up individual bundles.
        // `end` finalizes amount purchased. it's -1 because buys are inclusive.
        // `player` is simply the person who's bundle of tickets these are.
        _ticketBundles[currentTicketId] = TicketBundle({
            end: currentTicketId + amount - 1,
            player: to
        });

        // push `_currentTicketId` to array as we can loop through and more
        // efficiently see whos tickets are whos when using as it as the key.
        _bundleFirstTicketId.push(currentTicketId);

        // update what ticket number we are on
        currentTicketId += amount;
    }

    /// @notice pulls the winning ticket for all to see yay
    /// @dev `_sortaRandom` is calculated by taking the block hash of the block
    /// we specified to end ticket purchases on plus a buffer. This is difficult
    /// to manipulate and predict. Then we get the remainder of it divided by
    /// tickets purchased that becomes more difficult to predict the more volume
    /// there is(?) That remainder is the winning ticket number.
    /// @return the "random" number, how many tickets created, and the winning
    /// number. This is to create transparency hopefully.
    function _calculateWinningInfo() private view returns (uint256[3] memory) {
        uint256 _sortaRandom = uint256(blockhash(endingBlock + pauseBuffer));

        return [_sortaRandom, currentTicketId, _sortaRandom % currentTicketId];
    }
}
