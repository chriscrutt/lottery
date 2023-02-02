// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    mapping(address => PlayerRounds) private _playerInfo;

    TicketBundle[] private _ticketBundles;

    uint256 private _allTimeTicketNum;

    uint256 private _ticketNum;

    uint256 private _roundNumber;

    event TicketsMinted(address to, uint256 amount);

    constructor() {
        _ticketBundles.push();
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

    function _playerStats(address player) internal view virtual returns (uint256, uint256, uint256) {
        return (
            _playerInfo[player].alltimeTickets,
            _playerInfo[player].currentTickets,
            _playerInfo[player].mostRecentRound
        );
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

    function _totalTicketsAllTime() internal view virtual returns (uint256) {
        return _allTimeTicketNum;
    }

    function _cirrculatingTickets() internal view virtual returns (uint256) {
        return _ticketNum;
    }

    function _round() internal view virtual returns (uint256) {
        return _roundNumber;
    }

    function _reset() internal virtual {
        delete _ticketBundles;
        _allTimeTicketNum += _ticketNum;
        _ticketNum = 0;
        _ticketBundles.push();
        _roundNumber++;
    }
}
