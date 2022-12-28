// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/// @title LottoTickets
/// @author The name of the author
/// @notice The contract that will be interacting with the tickets
/// @dev allows the minting of tickets, finding a specific ticket holder's address, and resetting
/// all ticket holdings

/// TODO
/// Interpolation Search?
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

    // tickets were minted/bought
    event TicketsMinted(address account, uint256 amount);

    /// @dev _bundleBuyer is an array so we can easily delete all maps and thus need to give it a
    /// length of 1 initiallys
    constructor() {
        _bundleBuyer.push();
    }

    /// @return uint256 gets the ticket ID of the next purchaed ticket
    function currentTicketId() public view returns (uint256) {
        return _currentTicketId;
    }

    /// @notice finding ticket number owner
    /// @param ticketId of the ticket who's address we are trying to find
    /// @return address of the person who's ticket we had
    function findTicketOwner(uint256 ticketId) public view returns (address) {
        require(ticketId < _currentTicketId, "ticket ID out of bounds");
        return _findTicketOwner(ticketId);
    }

    /// @notice updates amount of tickets purchased and by who
    /// @dev first initialized a new bundle using `_currentTicketId` and adds it to an array to
    /// help loop through the map. Then changes `_currentTicketId` to take into account the `amount`
    /// that was just minted.
    /// @param to the wallet tickets are to be bought for
    /// @param amount of tickets that are to be bought
    function _mintTickets(address to, uint256 amount) internal {
        _bundleBuyer[0][_currentTicketId] = to;

        _bundleFirstTicketNum.push(_currentTicketId);

        _currentTicketId += amount;

        emit TicketsMinted(to, amount);
    }

    /// @notice deletes all records of tickets and ticket holders
    function _reset() internal virtual {
        delete _bundleBuyer;
        delete _bundleFirstTicketNum;
        _currentTicketId = 0;
        _bundleBuyer.push();
    }

    /// @notice finds ticket number owner
    /// @dev uses binary search (as opposed to linear/jump/interpolation).
    /// "unchecked" as there'd be no way to overflow/underflow/divide by zero (supposedly).
    /// there's a lot of lingo on the "net", but what I've found is that binary search is well worth
    /// it even with only a small array length. I've heard interpolation can be better but I'm not
    /// sure if it would be worth it in solidity because of all the mathematical equations it'd have
    /// to solve- even if it runs fewer times it might be more gas intensive.
    /// @param ticketId of the ticket who's address we are trying to find
    /// @return address of the person who's ticket we had
    /**
     * @dev Finds the owner of a ticket with a given ID.
     *
     * @param ticketId The ID of the ticket to find the owner of.
     * @return The address of the owner of the ticket.
     */
    function _findTicketOwner(
        uint256 ticketId // The ID of the ticket to find the owner of
    ) public view returns (address) {
        // The function is marked as internal and view and returns the address of the owner
        unchecked {
            // The unchecked block is used to disable Solidity's overflow checking for the duration of the block
            uint256 high = _bundleFirstTicketNum.length; // Initialize high to the length of the _bundleFirstTicketNum array
            uint256 len = high; // Initialize len to the same value as high
            uint256 low = 1; // Initialize low to 1
            uint256 mid = (low + high) >> 1; // Calculate the middle index of the search range as the average of l and h
            // Enter a while loop that continues as long as mid is less than len
            while (mid < len) {
                // If ticketId is greater than the value at index mid in _bundleFirstTicketNum
                if (ticketId > _bundleFirstTicketNum[mid]) {
                    low = mid + 1; // Set low to mid + 1
                }
                // If ticketId is less than the value at index mid in _bundleFirstTicketNum
                else if (ticketId < _bundleFirstTicketNum[mid]) {
                    // If ticketId is also less than the value at index mid - 1 in _bundleFirstTicketNum
                    if (ticketId < _bundleFirstTicketNum[mid - 1]) {
                        high = mid - 1; // Set high to mid - 1
                    }
                    // If ticketId is greater than or equal to the value at index mid - 1 in _bundleFirstTicketNum
                    else if (ticketId >= _bundleFirstTicketNum[mid - 1]) {
                        return _bundleBuyer[0][_bundleFirstTicketNum[mid - 1]]; // Return the owner of the ticket with ID _bundleFirstTicketNum[mid - 1]
                    }
                }
                // If ticketId is equal to the value at index mid in _bundleFirstTicketNum
                else if (ticketId == _bundleFirstTicketNum[mid]) {
                    return _bundleBuyer[0][_bundleFirstTicketNum[mid]]; // Return the owner of the ticket with ID _bundleFirstTicketNum[mid]
                }
                mid = (low + high) / 2; // Calculate the new middle index of the search range
            }
            return _bundleBuyer[0][_bundleFirstTicketNum[len - 1]]; // Return the owner of the ticket with ID _bundleFirstTicketNum[len - 1]
        }
    }
}
