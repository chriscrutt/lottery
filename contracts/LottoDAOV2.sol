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
 
 */

contract LottoRewardsToken is ERC777 {
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

abstract contract LottoDAO is LottoGratuity {
    using Math for uint256;

    LottoRewardsToken private _lottoRewardsToken;
    StakingContract private _stakingContract;

    uint256 private _rewardsPerBlock;

    uint256 private _daoGratuity;

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
        // constructor(address[] memory beneficiaries, uint256[] memory gratuityTimes1000)
        _lottoRewardsToken = new LottoRewardsToken(rewardTokenName, rewardTokenSymbol, _makeOwner());
        _stakingContract = new StakingContract(address(_lottoRewardsToken));
        _rewardsPerBlock = rewardsPerBlock;
        require(daoGratuity > 0, "DAO must get some reward");
        _addBeneficiary(address(_stakingContract), daoGratuity);
    }

    function payoutAndRestart() public virtual {
        require(block.number > _lotteryEndsAfterBlock(), "lottery time isn't up");
        require(address(this).balance >= _potMinimum(), "minimum pot hasn't been reached");
        uint256 blockDif = block.number - _lotteryEndsAfterBlock();
        uint256 balance = address(this).balance;
        _payout(balance);
        _stakingContract.receivedPayout(_daoGratuity * balance);
        _start(blockDif);
    }

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

    function _makeOwner() private view returns (address[] memory) {
        address[] memory own = new address[](1);
        own[0] = address(this);
        return own;
    }
}
