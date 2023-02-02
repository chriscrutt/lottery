// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**

TODO

[ ] make more gas-efficient
[ ] add ignore to functions mixed up because where they are placed right now makes it flow better
[ ] add NatSpec


 */

contract LottoTicketsV2 {
    struct PlayerRounds {
        uint256 alltimeTickets;
        uint256 currentTickets;
        uint256 mostRecentRound;
    }

    struct TicketBundle {
        uint256 startingTicket;
        uint256 endingTicket;
        address bundleOwner;
    }

    TicketBundle[] private _ticketBundles;

    mapping(address => PlayerRounds) private _playerInfo;

    uint256 private _allTimeTicketNum;

    uint256 private _ticketNum;

    uint256 private _roundNumber;

    event TicketsMinted(address to, uint256 amount);

    constructor() {
        _ticketBundles.push();
    }

    function _playerStats(address player) internal view virtual returns (PlayerRounds memory) {
        return (_playerInfo[player]);
    }

    function _totalTicketsAllTime() internal view virtual returns (uint256) {
        return _allTimeTicketNum;
    }

    function _cirrculatingTickets() internal view virtual returns (uint256) {
        return _ticketNum;
    }

    function _round() internal view virtual returns (uint256) {
        return _roundNumber;
    }

    function _mintTickets(address to, uint256 amount) internal virtual {
        _ticketBundles[_ticketBundles.length - 1] = TicketBundle(_ticketNum, _ticketNum + amount, to);
        _ticketNum += amount + 1;
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

    function _findTicketOwner(
        uint256 ticketNum,
        TicketBundle[] memory ticketBundles
    ) internal pure virtual returns (address) {
        uint256 low = 0;
        uint256 high = ticketBundles.length - 1;

        while (low <= high) {
            uint256 mid = (low + high) / 2;

            if (ticketBundles[mid].startingTicket <= ticketNum && ticketNum <= ticketBundles[mid].endingTicket) {
                return ticketBundles[mid].bundleOwner;
            } else if (ticketBundles[mid].endingTicket < ticketNum) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }

        // return address(0);
        revert("address not found");
    }

    function _reset() internal virtual {
        delete _ticketBundles;
        _allTimeTicketNum += _ticketNum;
        _ticketNum = 0;
        _ticketBundles.push();
        _roundNumber++;
    }
}
