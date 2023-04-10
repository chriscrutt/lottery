// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

TODO

[x] make more gas-efficient
[?] add ignore to functions mixed up because where they are placed right now makes it flow better
[x] add NatSpec
[x] when to make functions public, external, private, internal


 */

contract LottoTicketsV2 {
    // just some metadata on our players for fun
    struct PlayerRounds {
        uint256 alltimeTickets;
        uint256 currentTickets;
        uint256 mostRecentRound;
    }

    // allows players to deposit any amount of tickets
    struct TicketBundle {
        uint256 startingTicket;
        uint256 endingTicket;
        address bundleOwner;
    }

    // array that orders ticket bundles in order of purchase
    TicketBundle[] private _ticketBundles;

    // allows for easy lookup of player metadata
    mapping(address => PlayerRounds) private _playerInfo;

    // all time amount of tickets purchased
    uint256 private _allTimeTicketNum;

    // next ticket number to be bought
    uint256 private _ticketNum;

    // how many lottery rounds have been started
    uint256 private _roundNumber;

    // tickets BOUGHT
    event TicketsMinted(address to, uint256 amount);

    /**
     * @notice metadata on players
     * @param player!
     */
    function playerStats(address player) public view virtual returns (PlayerRounds memory) {
        return (_playerInfo[player]);
    }

    /**
     * @notice total tickets bought all time!
     */
    function totalTicketsAllTime() public view virtual returns (uint256) {
        return _allTimeTicketNum;
    }

    /**
     * @notice current tickets circulating
     */
    function circulatingTickets() public view virtual returns (uint256) {
        return _ticketNum;
    }

    /**
     * @notice round number!
     */
    function round() public view virtual returns (uint256) {
        return _roundNumber;
    }

    /**
     * @notice find the owner of a ticket number
     * @param ticketNum ber!
     */
    function findTicketOwner(uint256 ticketNum) public view virtual returns (address) {
        return _findTicketOwner(ticketNum);
    }

    /**
     * @dev create new bundle, update user metadata, emit ticket purchase event
     * @param to player to mint tickets to
     * @param amount of tickets to be minted
     */
    function _mintTickets(address to, uint256 amount) internal virtual {
        _ticketBundles.push(TicketBundle(_ticketNum, _ticketNum + amount, to));
        _ticketNum += amount;
        _allTimeTicketNum += amount;
        if (_playerInfo[to].mostRecentRound == _roundNumber) {
            _playerInfo[to].alltimeTickets += amount;
            _playerInfo[to].currentTickets += amount;
        } else {
            _playerInfo[to].alltimeTickets += amount;
            _playerInfo[to].currentTickets = amount;
            _playerInfo[to].mostRecentRound = _roundNumber;
        }
        emit TicketsMinted(to, amount);
    }

    /**
     * @dev deletes all the ticket bundles, adds to all time tickets bought, and increases round num
     */
    function _reset() internal virtual {
        delete _ticketBundles;
        _ticketNum = 0;
        ++_roundNumber;
    }

    /**
     * @notice binary search to look through bundles to find the bundle/ticket owner
     * @param ticketNum to find player
     */
    function _findTicketOwner(uint256 ticketNum) internal view virtual returns (address) {
        TicketBundle[] memory bundle = _ticketBundles;

        uint256 low = 0;
        uint256 high = bundle.length - 1;

        while (low <= high) {
            uint256 mid = (low + high) / 2;

            if (bundle[mid].startingTicket <= ticketNum && ticketNum <= bundle[mid].endingTicket) {
                return bundle[mid].bundleOwner;
            } else if (bundle[mid].endingTicket < ticketNum) {
                low = ++mid;
            } else {
                high = --mid;
            }
        }

        revert("address not found");
    }
}
