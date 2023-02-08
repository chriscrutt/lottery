// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LottoDAOV2.sol";

contract Implementation is LottoDAO {
    
    constructor(
        address[] memory beneficiaries,
        uint256[] memory gratuityTimes1000
    )
        LottoDAO(
            "Reward Token Name", // token name
            "RTN", // token symbol
            21e18, // rewards per block (21 tokens)
            beneficiaries, // beneficiaries
            gratuityTimes1000, // their respective gratuities so 10% = 0.10 * 1000 = 100
            50,
            1, // minimum pot in wei
            6 // lottery block length
        )
    {}
}
