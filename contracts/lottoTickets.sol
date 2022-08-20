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
/// enable staking and withdrawing
/// add comments

contract LottoTickets {
    // the starting ticket of each bundle purchased
    uint256[] public _bundleFirstTicketNum;
    // checks what bundle was bought by who
    mapping(uint256 => address) public _bundleBuyer;
    // what is the next ticket number to be purchased
    uint256 private _currentTicketId;

    constructor() {}

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
        _bundleBuyer[_currentTicketId] = to;

        // push `_currentTicketId` to array as we can loop through and more
        // efficiently see whos tickets are whos when using as it as the key.
        _bundleFirstTicketNum.push(_currentTicketId);

        // update what ticket number we are on
        _currentTicketId += amount;
    }

    /// @notice finds a ticket's owner
    /// @param ticketId is the ticket we wish to find who's it is
    /// @return the address of the ticket owner!
    function _findTicketOwner(uint256 ticketId)
        internal
        view
        returns (address)
    {       // 2        100000
        if (ticketId < _currentTicketId) {
            // 0, 1, 2, 3 = 4
            uint256 len = _bundleFirstTicketNum.length;
            for (uint256 i = 1; i < len; ++i) {
                // 100 !< 0 !< 1 !< 2 < 1000000000000002
                if (ticketId < _bundleFirstTicketNum[i]) {
                    // return address
                    return _bundleBuyer[_bundleFirstTicketNum[i - 1]];
                }
            }
            return _bundleBuyer[_bundleFirstTicketNum[len - 1]];
        }
        revert();
    }

    function findTicketOwner(uint256 ticketId) public view returns (address) {
        return _findTicketOwner(ticketId);
    }

    function _reset() internal virtual {
        for (uint256 i = 0; i < _bundleFirstTicketNum.length; ++i) {
            delete _bundleBuyer[_bundleFirstTicketNum[i]];
        }
        delete _bundleFirstTicketNum;
        _currentTicketId = 0;
    }
}
