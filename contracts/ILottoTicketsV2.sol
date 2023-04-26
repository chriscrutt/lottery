// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILottoTicketsV2 {
    // just some metadata on our players for fun
    struct PlayerRounds {
        uint256 alltimeTickets;
        uint256 currentTickets;
        uint256 mostRecentRound;
    }

    // tickets BOUGHT
    event TicketsMinted(address to, uint256 amount);

    /**
     * @notice metadata on players
     * @param player!
     */
    function playerStats(address player) external view returns (PlayerRounds memory);

    /**
     * @notice total tickets bought all time!
     */
    function totalTicketsAllTime() external view returns (uint256);

    /**
     * @notice current tickets circulating
     */
    function circulatingTickets() external view returns (uint256);

    /**
     * @notice round number!
     */
    function round() external view returns (uint256);

    /**
     * @notice find the owner of a ticket number
     * @param ticketNum ber!
     */
    function findTicketOwner(uint256 ticketNum) external view returns (address);
}
