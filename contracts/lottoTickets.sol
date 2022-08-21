// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// TODO
/// see cheaper options
/// reorder functions
/// remove unneccessary
///     variables
///     functions
///     visibilities
///     imports (like math)
/// add comments
/// subtract before sending funds
/// see if loop runs out of gas
/// make sure ALL eth gets sent
/// pretty sure "mid - 1" will never underflow for `_findTicketOwner` because
///     mid would have to = 0 which would mean high < low which can't happen
///     because we would have iterated through all numbers by then?

contract LottoTickets {
    // the starting ticket of each bundle purchased
    uint256[] private _bundleFirstTicketNum;
    // checks what bundle was bought by who
    mapping(uint256 => address)[] private _bundleBuyer;
    // what is the next ticket number to be purchased
    uint256 private _currentTicketId;

    constructor() {
        _bundleBuyer.push();
    }

    function currentTicketId() public view returns (uint256) {
        return _currentTicketId;
    }

    /// @notice updates amount of tickets purchased and by who
    /// @param to the wallet tickets are to be bought for
    /// @param amount the wallet tickets are to be bought for
    function _mintTickets(address to, uint256 amount) internal {
        // using `_currentTicketId` as key to look up individual bundles.
        // `end` finalizes amount purchased. it's -1 because buys are inclusive.
        // `player` is simply the person who's bundle of tickets these are.
        _bundleBuyer[0][_currentTicketId] = to;

        // push `_currentTicketId` to array as we can loop through and more
        // efficiently see whos tickets are whos when using as it as the key.
        _bundleFirstTicketNum.push(_currentTicketId);

        // update what ticket number we are on
        _currentTicketId += amount;
    }

    // /// @notice finds a ticket's owner
    // /// @param ticketId is the ticket we wish to find who's it is
    // /// @return the address of the ticket owner!
    // function _findTicketOwner(uint256 ticketId)
    //     internal
    //     view
    //     returns (address)
    // {
    //     // 2        100000
    //     if (ticketId < _currentTicketId) {
    //         // 0, 1, 2, 3 = 4
    //         uint256 len = _bundleFirstTicketNum.length;
    //         for (uint256 i = 1; i < len; ++i) {
    //             // 100 !< 0 !< 1 !< 2 < 1000000000000002
    //             if (ticketId < _bundleFirstTicketNum[i]) {
    //                 // return address
    //                 return _bundleBuyer[0][_bundleFirstTicketNum[i - 1]];
    //             }
    //         }
    //         return _bundleBuyer[0][_bundleFirstTicketNum[len - 1]];
    //     }
    //     revert();
    // }

    function _findTicketOwner(uint256 ticketId)
        internal
        view
        returns (address)
    {
        unchecked {
            uint256 high = _bundleFirstTicketNum.length;
            uint256 len = high;
            uint256 low = 1;
            uint256 mid = (low + high) / 2;
            while (mid < len) {
                if (ticketId > _bundleFirstTicketNum[mid]) {
                    low = mid + 1;
                } else if (ticketId < _bundleFirstTicketNum[mid]) {
                    if (ticketId < _bundleFirstTicketNum[mid - 1]) {
                        high = mid - 1;
                    } else if (ticketId >= _bundleFirstTicketNum[mid - 1]) {
                        return _bundleBuyer[0][_bundleFirstTicketNum[mid - 1]];
                    }
                } else if (ticketId == _bundleFirstTicketNum[mid]) {
                    return _bundleBuyer[0][_bundleFirstTicketNum[mid]];
                }
                mid = (low + high) / 2;
            }
            return _bundleBuyer[0][_bundleFirstTicketNum[len - 1]];
        }
    }

    function findTicketOwner(uint256 ticketId) public view returns (address) {
        require(ticketId < _currentTicketId, "ticket ID out of bounds");
        return _findTicketOwner(ticketId);
    }

    function _reset() internal virtual {
        delete _bundleBuyer;
        delete _bundleFirstTicketNum;
        _currentTicketId = 0;
        _bundleBuyer.push();
    }
}
