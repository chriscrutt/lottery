// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// import "./LottoDAOV2.sol";

// // solhint-disable no-empty-blocks

// contract Implementation is LottoDAO {
//     /**
//      * @notice creates a lottery that runs via a DAO!
//      * @param beneficiaries is an array of addresses to collect rewards
//      * @param gratuityTimes1000 how much they're earning -> 10% = 0.10 * 1000 = 100
//      * then LottoDAO is created accordingly
//      * @dev
//      * rewardTokenName, rewardTokenSymbol, rewardsPerBlock, daoGratuity, decayNumerator_, decayDenomonator_,
//      * beneficiaries, gratuityTimes1000, minPot_, lottoLength_, securityBeforeDraw_, securityAfterDraw_
//      *
//      */
//     constructor(
//         address[] memory beneficiaries,
//         uint256[] memory gratuityTimes1000
//     ) LottoDAO("Reward Token", "RTN", 21e18, 250, 999, 1000, beneficiaries, gratuityTimes1000, 1000, 6, 1, 1) {}
// }

// import "./LottoDAOV2.sol";

// contract Implementation is LottoDAO {
//     constructor(
//         address[] memory beneficiaries,
//         uint256[] memory gratuityTimes1000
//     ) LottoDAO("Rewards Token", "RWT", 21e18, 250, 999, 1000, beneficiaries, gratuityTimes1000, 1000, 6, 1, 1) {}
// }

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

/**
 * @notice allows the owning contract can mint!
 * @dev this makes it so those who help restart the lottery earn token rewards.
 * Those rewards can then be staked to earn a percentage of Ether the DAO is allotted
 */
contract Implementation is ERC777 {
    /**
     * @dev owners are "default operators" which pretty much just means they have authority to spend anyone's tokens
     * @param rewardTokenName the name of the reward token
     * @param rewardTokenSymbol the symbol of the reward token
     * @param owners the default operators of the contract (should be just contract creator in this case)
     */
    constructor(
        string memory rewardTokenName,
        string memory rewardTokenSymbol,
        address[] memory owners
    ) ERC777(rewardTokenName, rewardTokenSymbol, owners) {}

    function mint(address account, uint256 amount) external {
        require(isOperatorFor(_msgSender(), address(0)), "not contract owner");
        _mint(account, amount, "", "");
    }
}