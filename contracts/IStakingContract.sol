// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// every lottery payout
struct Payouts {
    uint256 amount;
    uint256 totalStakedSupply;
    uint256 blockNumber;
}

/**
 * @dev Interface of StakingContract
 */
interface IStakingContract {
    receive() external payable;

    /**
     * @notice stakes tokens
     * @param tokensToStake tokens to stake
     */
    function stake(uint256 tokensToStake) external returns (bool);

    /**
     * @notice unstakes tokens
     * @param tokensToUnstake tokens to unstake
     */
    function unstake(uint256 tokensToUnstake) external returns (bool);

    /**
     * @notice withdraws available ether rewards
     * @param amount ether to claim
     */
    function withdrawRewards(uint256 amount) external returns (bool);

    /**
     * @notice returns array of lottery payouts
     * @param id of payout
     */
    function payoutInfo(uint256 id) external view returns (Payouts memory);

    /**
     * @notice returns total amount of tokens staked
     */
    function totalCurrentlyStaked() external view returns (uint256);

    /**
     * @notice returns total amount of ether available to withdraw
     */
    function withdrawableEth(address account) external view returns (uint256);
}
