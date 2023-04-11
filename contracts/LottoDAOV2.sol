// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LottoGratuityV2.sol";
import "./StakingContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**

TODO

[x] make payout internal?
[x] see if you can get rid of any redundant imports
[x] gas stuff
[x] include constructor param that lets you sent rate of decay for DAO token?
[ ] make some internal/private functions public?
[ ] make sure daoGratuity also isn't 1000
[ ] make it so all token transfers potentially can have callbacks when sent to smart contracts?
[x] back to erc20
[ ] better payout gratuity
[ ] tf up with _start

 */

contract LottoRewardsToken is ERC20 {
    /**
     * @dev owners are "default operators" which pretty much just means they have authority to spend anyone's tokens
     * @param name the name of the reward token
     * @param symbol the symbol of the reward token
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {} // solhint-disable-line no-empty-blocks
}

/**
 * @notice allows for anyone to restart the lottery for a reward!
 * @dev an itteration of LottoGratuity that allows for a DAO token to be minted when the lottery is restarted
 * they can then stake the tokens in the StakingContract and earn ether rewards that get sent via a specified gratuity
 */
abstract contract LottoDAO is LottoGratuity {
    // mainly for mulDiv() because it is cheaper somehow
    using Math for uint256;

    uint256 private _startingBlock;
    uint256 private _lastRewardBlock;
    uint256 private _totalPlannedBlocks;

    // for the ERC777 that will be the DAO token
    LottoRewardsToken private _lottoRewardsToken;
    // allows people to stake the DAO token to receive ether rewards
    StakingContract private _stakingContract;

    // what gratuity the DAO/staking contract will be receiving per lottery payout
    uint256 private _daoGratuity;

    /**
     * @dev sets up EVERYTHING. includes info that'll make the DAO token and staking contract
     * it also initializes LottoGratuity which in turn initializes BasicLotto
     * @param rewardTokenName name of DAO token
     * @param rewardTokenSymbol symbol of DAO token
     * @param totalPlannedBlocks asdf
     * @param beneficiaries addresses that will be earning a percentage of the pot each payout
     * @param gratuityTimes1000 gratuity per beneficiary so that 10% = 0.10 but * 1000 = 100
     * @param daoGratuity gratuity the DAO/staking contract should receive
     * @param minPot_ the minimum pot in wei in order for the lottery to conclude
     * @param lottoLength_ length in blocks since (re)start the lottery should go
     * @param securityBeforeDraw_ amount of blocks before draw for finality
     * @param securityAfterDraw_ amount of blocks after draw for finality
     */
    constructor(
        string memory rewardTokenName,
        string memory rewardTokenSymbol,
        uint256 totalPlannedBlocks,
        uint256 daoGratuity,
        address[] memory beneficiaries,
        uint256[] memory gratuityTimes1000,
        uint256 minPot_,
        uint256 lottoLength_,
        uint256 securityBeforeDraw_,
        uint256 securityAfterDraw_
    ) LottoGratuity(beneficiaries, gratuityTimes1000, minPot_, lottoLength_, securityBeforeDraw_, securityAfterDraw_) {
        address[] memory owner = new address[](1);
        owner[0] = address(this);
        _lottoRewardsToken = new LottoRewardsToken(rewardTokenName, rewardTokenSymbol);
        // _stakingContract = new StakingContract(address(_lottoRewardsToken));
        _totalPlannedBlocks = totalPlannedBlocks;
        require(daoGratuity > 0, "DAO must get some reward");
        // _addBeneficiary(address(_stakingContract), daoGratuity);

        _startingBlock = block.number;
        _lastRewardBlock = block.number;
    }

    function calculateTokenReward() public virtual returns (uint256) {
        uint256 blockRewards;
        uint256 blockNumber_ = block.number;
        uint256 totalPlannedBlocks_ = _totalPlannedBlocks;
        uint256 startingBlock_ = _startingBlock;
        uint256 lastRewardBlock_ = _lastRewardBlock;
        _lastRewardBlock = blockNumber_;
        if (totalPlannedBlocks_ > blockNumber_ - startingBlock_) {
            unchecked {
                blockRewards =
                    (((blockNumber_ - lastRewardBlock_) *
                        (2 * (totalPlannedBlocks_ + startingBlock_) - lastRewardBlock_ - blockNumber_)) / 2) *
                    10 ** 10;
            }
        } else {
            blockRewards = blockNumber_ - lastRewardBlock_;
        }
        return blockRewards;
    }



    /**
     * @notice pays out winners and beneficiaries and restarts the lottery while receiving rewards tokens!
     * @dev makes sure the lottery timer is over and balance reached the minimum pot.
     * uses some internal functions as we do not have access to private variables
     */
    function payoutAndRestart() public virtual nonReentrant {
        require(
            lottoDeadline() + blocksBeforeDraw() + blocksAfterDraw() <
                block.number,
            "wait for finality"
        );
        require(
            address(this).balance >= minimumPot(),
            "minimum pot hasn't been reached"
        );
        uint256 blockDif = block.number -
            (lottoDeadline() + blocksBeforeDraw() + blocksAfterDraw());
        uint256 balance = address(this).balance;
        _payout(balance);
        _stakingContract.receivedPayout(_daoGratuity * balance);
        _start(blockDif);
    }

    
    // /**
    //  * @notice starts the lottery after payout
    //  * rewards per block depreciate at a rate of 0.1% each block and adds them together until the lottery is started
    //  * it does this by iterating through each block since the lottery ended and then finally updates state variable
    //  * @param blockDif is used to calculate the amount of DAO tokens to mint.
    //  */
    // function _start(uint256 blockDif) internal virtual {
    //     uint256 tokensToReward = 0;
    //     uint256 tmpRewardsPerBlock = _rewardsPerBlock;

    //     for (uint256 i = 0; i < blockDif; ++i) {
    //         tokensToReward += tmpRewardsPerBlock;
    //         tmpRewardsPerBlock = tmpRewardsPerBlock.mulDiv(
    //             _decayNumerator,
    //             _decayDenomonator,
    //             Math.Rounding.Up
    //         );
    //     }

    //     _rewardsPerBlock = tmpRewardsPerBlock;
    //     _lottoRewardsToken.transferAndCall(_msgSender(), tokensToReward);
    // }
}
