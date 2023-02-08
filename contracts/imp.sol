// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LottoDAOV2.sol";

contract Implementation is LottoDAO {
    // solhint-disable no-empty-blocks
    /**
     * @notice creates a lottery that runs via a DAO!
     * @param beneficiaries is an array of addresses to collect rewards
     * @param gratuityTimes1000 how much they're earning -> 10% = 0.10 * 1000 = 100
     * then LottoDAO is created accordingly
     * token name, symbol, rewards per block, beneficiaries, gratuity, DAO gratuity, minimum pot wei, lottery time
     *
     */
    constructor(
        address[] memory beneficiaries,
        uint256[] memory gratuityTimes1000
    ) LottoDAO("Reward Token", "RTN", 21e18, beneficiaries, gratuityTimes1000, 50, 1, 6) {}
}
