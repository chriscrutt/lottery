// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LottoGratuityV2.sol";
import "./StakingContract.sol";
import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

/**

TODO

[ ] make payout internal?
[ ] see if you can get rid of any redundant imports
[ ] gas stuff
[ ] include constructor param that lets you sent rate of decay for DAO token?
 
 */

/**
 * @notice allows the owning contract can mint!
 * @dev this makes it so those who help restart the lottery earn token rewards.
 * Those rewards can then be staked to earn a percentage of Ether the DAO is allotted
 */
contract LottoRewardsToken is ERC777 {
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

/**
 * @notice allows for anyone to restart the lottery for a reward!
 * @dev an itteration of LottoGratuity that allows for a DAO token to be minted when the lottery is restarted
 * they can then stake the tokens in the StakingContract and earn ether rewards that get sent via a specified gratuity
 */
abstract contract LottoDAO is LottoGratuity {
    // mainly for mulDiv() because it is cheaper somehow
    using Math for uint256;

    // for the ERC777 that will be the DAO token
    LottoRewardsToken private _lottoRewardsToken;
    // allows people to stake the DAO token to receive ether rewards
    StakingContract private _stakingContract;

    // current DAO tokens minted per block after the lottery has concluded
    uint256 private _rewardsPerBlock;

    // what gratuity the DAO/staking contract will be receiving per lottery payout
    uint256 private _daoGratuity;

    /**
     * @dev sets up EVERYTHING. includes info that'll make the DAO token and staking contract
     * it also initializes LottoGratuity which in turn initializes BasicLotto
     * @param rewardTokenName name of DAO token
     * @param rewardTokenSymbol symbol of DAO token
     * @param beneficiaries addresses that will be earning a percentage of the pot each payout
     * @param gratuityTimes1000 gratuity per beneficiary so that 10% = 0.10 but * 1000 = 100
     * @param daoGratuity gratuity the DAO/staking contract should receive
     * @param minPot_ the minimum pot in wei in order for the lottery to conclude
     * @param lottoLength_ length in blocks since (re)start the lottery should go
     */
    constructor(
        string memory rewardTokenName,
        string memory rewardTokenSymbol,
        uint256 rewardsPerBlock,
        address[] memory beneficiaries,
        uint256[] memory gratuityTimes1000,
        uint256 daoGratuity,
        uint256 minPot_,
        uint256 lottoLength_
    ) LottoGratuity(beneficiaries, gratuityTimes1000, minPot_, lottoLength_) {
        _lottoRewardsToken = new LottoRewardsToken(rewardTokenName, rewardTokenSymbol, _makeOwner());
        _stakingContract = new StakingContract(address(_lottoRewardsToken));
        _rewardsPerBlock = rewardsPerBlock;
        require(daoGratuity > 0, "DAO must get some reward");
        _addBeneficiary(address(_stakingContract), daoGratuity);
    }

    /**
     * @notice pays out winners and beneficiaries and restarts the lottery while receiving rewards tokens!
     * @dev makes sure the lottery timer is over and balance reached the minimum pot.
     * uses some internal functions as we do not have access to private variables
     */
    function payoutAndRestart() public virtual {
        require(block.number > _lotteryEndsAfterBlock(), "lottery time isn't up");
        require(address(this).balance >= _potMinimum(), "minimum pot hasn't been reached");
        uint256 blockDif = block.number - _lotteryEndsAfterBlock();
        uint256 balance = address(this).balance;
        _payout(balance);
        _stakingContract.receivedPayout(_daoGratuity * balance);
        _start(blockDif);
    }

    /**
     * @notice starts the lottery after payout
     * rewards per block depreciate at a rate of 0.1% each block and adds them together until the lottery is (re)started
     * it does this by iterating through each block since the lottery ended and then finally updates state variable
     * @param blockDif is used to calculate the amount of DAO tokens to mint.
     */
    function _start(uint256 blockDif) internal virtual {
        uint256 tokensToReward = 0;
        uint256 tmpRewardsPerBlock = _rewardsPerBlock;

        for (uint256 i = 0; i < blockDif; ++i) {
            tokensToReward += tmpRewardsPerBlock;
            tmpRewardsPerBlock = tmpRewardsPerBlock.mulDiv(999, 1000, Math.Rounding.Up);
        }

        _rewardsPerBlock = tmpRewardsPerBlock;
        _lottoRewardsToken.mint(msg.sender, tokensToReward);
    }

    /**
     * @notice to initialize current contract as owner/default operator for ERC777/DAO token
     */
    function _makeOwner() private view returns (address[] memory) {
        address[] memory own = new address[](1);
        own[0] = address(this);
        return own;
    }
}
