// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract LottoTickets {
    // the starting ticket of each bundle purchased
    uint256[] private _bundleFirstTicketNum;
    // checks what bundle was bought by who
    mapping(uint256 => address) private _bundleBuyer;
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
    {
        uint256 low = 0;
        uint256 high = _bundleFirstTicketNum.length;
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            if (
                _bundleFirstTicketNum[mid] <= ticketId &&
                _bundleFirstTicketNum[mid + 1] >= ticketId
            ) {
                return _bundleBuyer[_bundleFirstTicketNum[mid]];
            } else if (
                _bundleFirstTicketNum[low] <= _bundleFirstTicketNum[mid]
            ) {
                if (
                    ticketId >= _bundleFirstTicketNum[low] &&
                    ticketId < _bundleFirstTicketNum[mid]
                ) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            } else {
                if (
                    ticketId <= _bundleFirstTicketNum[high - 1] &&
                    ticketId > _bundleFirstTicketNum[mid]
                ) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        revert();
    }

    function _reset() internal virtual {
        for (uint256 i = 0; i < _bundleFirstTicketNum.length; ++i) {
            delete _bundleBuyer[_bundleFirstTicketNum[i]];
        }
        delete _bundleFirstTicketNum;
        _currentTicketId = 0;
    }
}
