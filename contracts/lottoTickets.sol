// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";

contract LottoTickets is Context {
    // infinity or close to it haha
    uint256 private constant _INFINITY = 2**256 - 1;
    // when lottery ends
    uint256 private _endingBlock;
    // the starting ticket of each bundle purchased
    uint256[] private _startingTicketNumber;
    // checks what bundle was bought by who
    mapping(uint256 => address) private _bundleBuyer;

    constructor() {
        _endingBlock = block.number;
    }

    function _findTicketOwner(uint256 ticketId)
        internal
        view
        returns (address)
    {
        uint256 low = 0;
        uint256 high = _startingTicketNumber.length;
        while (low < high) {
            uint256 mid = low + (high - low) / 2;
            if (
                _startingTicketNumber[mid] <= ticketId &&
                _startingTicketNumber[mid + 1] >= ticketId
            ) {
                return _bundleBuyer[_startingTicketNumber[mid]];
            } else if (
                _startingTicketNumber[low] <= _startingTicketNumber[mid]
            ) {
                if (
                    ticketId >= _startingTicketNumber[low] &&
                    ticketId < _startingTicketNumber[mid]
                ) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            } else {
                if (
                    ticketId <= _startingTicketNumber[high - 1] &&
                    ticketId > _startingTicketNumber[mid]
                ) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        revert();
    }
}
