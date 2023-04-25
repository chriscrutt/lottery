// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// round info, easy
struct Round {
    address winner;
    uint256 pot;
}

interface ILottery {
    // on lottery payout
    event Payout(address to, uint256 amount);

    /**
     * @notice buy tickets
     */
    function buyTickets() external payable returns (bool);

    function payout() external returns (bool);

    /**
     * @notice see blocks to go by before drawing winner for security reasons
     */
    function payoutAvailableOnBlock() external view returns (uint256);

    /**
     * @notice get all lottery winners and pot
     */
    function lotteryLookup(uint256 id) external view returns (Round memory);

    function currentRoundId() external view returns (uint256);

    /**
     * @notice minimum pot
     */
    function minimumPot() external view returns (uint256);

    /**
     * @notice what block number will the lotto finish on
     */
    function lottoDeadline() external view returns (uint256);

    /**
     * @notice current block for player easy access
     */
    function currentBlock() external view returns (uint256);

    function roundLength() external view returns (uint256);
}
