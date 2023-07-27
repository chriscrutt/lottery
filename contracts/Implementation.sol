// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LottoDAOV2.sol";

// solhint-disable no-empty-blocks

contract Implementation is LottoDAO {
    /**
     * @notice creates a lottery that runs via a DAO!
     * @param beneficiaries is an array of addresses to collect rewards
     * @param gratuityTimes1000 how much they're earning -> 10% = 0.10 * 1000 = 100
     * then LottoDAO is created accordingly
     * @dev rewardTokenName, rewardTokenSymbol, rewardsPerBlock, daoGratuity beneficiaries,
     * gratuityTimes1000, minPot_, lottoLength_, securityBeforeDraw_, securityAfterDraw_
     *
     */
    constructor(
        address[] memory beneficiaries,
        uint256[] memory gratuityTimes1000
    )
        LottoDAO("Reward Token", "RTN", 70128000, 100)
        LottoGratuity(beneficiaries, gratuityTimes1000)
        Lotto(1000, 6, 1, 1)
    {}
}
