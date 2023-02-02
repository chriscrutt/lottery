/**

MINT TOKENS TO PEOPLE RESTARTING CONTRACT
ADD UNCHECKED OR OTHER THINGS TO ACCUMULATED ETHER
 */

/**
 * The LottoDAO contract is a decentralized autonomous organization (DAO) that handles a lottery
 * game. It is based on the LottoGratuity contract, which is an abstract contract that handles the
 * distribution of winnings to beneficiaries. The LottoDAO contract also includes a
 * LottoRewardsToken contract, which is an ERC20 token that allows users to start staking and
 * receive rewards.
 *
 * The LottoDAO contract has several functions that allow users to interact with the contract. The
 * startStaking() function allows users to start staking their tokens and receive rewards. The
 * withdrawFees() function allows users to withdraw any accumulated fees they have earned through
 * the DAO. The _logWinningPlayer() function records the winner, winnings, and block number in the
 * winning history array.
 *
 * The LottoDAO contract also has two private functions that are used to calculate the accumulated
 * ether for a user. The _accumulatedEtherLinear() function uses a linear search to find the
 * accumulated ether for a user, while the _accumulatedEtherBinary() function uses a binary search
 * to find the accumulated ether for a user. Both functions take in an address as a parameter and
 * return the accumulated ether as a uint256 value.
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lottoGratuity.sol";
import "./ERC80085.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LottoRewardsToken
 * @dev A ERC-20 token that allows users to stake tokens and earn rewards.
 * @notice Only the contract owner can call certain functions.
 */
contract LottoRewardsToken is ERC80085, Ownable {
    /**
     * @dev Creates a new instance of the LottoRewardsToken contract with the given name and symbol.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     */
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {} // solhint-disable-line no-empty-blocks

    /**
     * @dev Allows the contract owner to receive Ether.
     * @notice This function can only be called by the contract owner.
     */
    receive() external payable onlyOwner {} // solhint-disable-line no-empty-blocks

    /**
     * @dev Allows the caller to start staking tokens.
     */
    function startStaking() public {
        _startStaking(msg.sender);
    }

    /**
     * @dev Allows the contract owner to start staking tokens for a given account.
     * @param account The account to start staking tokens for.
     * @notice can only be called by the contract owner & not already be staking tokens.
     */
    function startStaking(address account) public onlyOwner {
        if (!isStaking(account)) {
            _startStaking(account);
        }
    }

    /**
     * @dev Allows the contract owner to transfer Ether to a given account.
     * @param to The account to transfer Ether to.
     * @param amount The amount of Ether to transfer.
     * @notice This function can only be called by the contract owner.
     */
    function transferEth(address to, uint256 amount) public onlyOwner {
        _transferEth(to, amount);
    }

    /**
     * @dev Allows the contract owner to mint new tokens and transfer them to a given account.
     * @param to The account to transfer the new tokens to.
     * @param amount The amount of tokens to mint and transfer.
     * @notice This function can only be called by the contract owner.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

abstract contract LottoDAO is LottoGratuity {
    // using BinarySearch for *;
    using Math for uint256;

    // will handle each lotto win
    struct WinningInfoDAO {
        address winner;
        uint256 winningAmount;
        uint256 ticket;
        uint256 blockNumber;
        uint256 feeAmount;
        uint256 totalStakedSupply;
    }

    WinningInfoDAO[] private _winningHistory;

    LottoRewardsToken public lottoRewardsToken;

    uint256 private _daoGratuity;
    uint256 private _lastPot;

    uint256 private _rewardsPerBlock;

    /**
     * @dev Constructor for the LottoGratuity contract. Initializes the LottoRewardsToken contract,
     * sets the rewards per block and DAO gratuity, and allows the caller to start staking tokens.
     * @param maxBeneficiaries The maximum number of beneficiaries allowed for the contract.
     * @param daoGratuity_ The percentage of winnings that go to the DAO gratuity * 1000
     */
    constructor(
        string memory rewardTokenName_,
        string memory rewardTokenSymbol_,
        uint8 maxBeneficiaries,
        uint256 daoGratuity_
    ) LottoGratuity(maxBeneficiaries, msg.sender, 0) {
        lottoRewardsToken = new LottoRewardsToken(rewardTokenName_, rewardTokenSymbol_);
        _rewardsPerBlock = 21e18;
        _daoGratuity = daoGratuity_;
        _swapBeneficiary(0, address(lottoRewardsToken), daoGratuity_);
        lottoRewardsToken.mint(msg.sender, 1);
    }

    /**
     * @dev Allows the caller to start staking tokens.
     */
    function startStaking() public {
        lottoRewardsToken.startStaking(msg.sender);
    }

    function isStaking() public view returns (bool) {
        return lottoRewardsToken.isStaking(msg.sender);
    }

    function lastWinner() public view override returns (address, uint256, uint256) {
        WinningInfoDAO memory win = _winningHistory[_winningHistory.length - 1];
        return (win.winner, win.winningAmount, win.ticket);
    }

    /**
     * @dev Withdraws accumulated fees for the caller, using either a linear search or binary
     * search depending on the length of the caller's transfer history.
     */
    function withdrawFees() public {
        address account = msg.sender;
        // uint256 yo = lottoRewardsToken.holderData(account).rewardsWithdrawn;
        uint256 eth = _accEth(account) - lottoRewardsToken.holderData(account).rewardsWithdrawn;
        lottoRewardsToken.holderData(account).rewardsWithdrawn += eth;
        lottoRewardsToken.transferEth(account, eth);
    }

    function accumulatedEth(address account) public view returns (uint256) {
        return _accEth(account);
    }

    function availableEth(address account) public view returns (uint256) {
        return _accEth(account) - lottoRewardsToken.holderData(account).rewardsWithdrawn;
    }

    function availableEth() public view returns (uint256) {
        return availableEth(msg.sender);
    }

    /**
     * @dev Pays out the specified amount to the contract owner and updates the last pot value.
     * @param amount The amount to be paid out.
     */
    function _payout(uint256 amount) internal virtual override {
        _lastPot = amount;
        super._payout(amount);
    }

    /**
     * @dev Records the winner, winnings, and block number in the winning history array.
     * @param account The address of the winning player.
     * @param winnings The amount won by the player.
     */
    function _logWinningPlayer(address account, uint256 winnings, uint256 ticketId) internal virtual override {
        _winningHistory.push(
            WinningInfoDAO({
                winner: account,
                winningAmount: winnings,
                ticket: ticketId,
                blockNumber: endingBlock(),
                feeAmount: _lastPot.mulDiv(_daoGratuity, 1000),
                totalStakedSupply: lottoRewardsToken.totalStakedSupply()
            })
        );
    }

    /**
     * @notice Rewards the caller with tokens based on the number of blocks that have passed since
     * the last reward was issued.
     * @dev Rewards per block decrease by 0.1% every block.
     */
    function _start() internal virtual override {
        super._start();

        uint256 blockDif = block.number - _winningHistory[_winningHistory.length - 1].blockNumber;

        uint256 tokensToReward = 0;
        uint256 tmpRewardsPerBlock = _rewardsPerBlock;

        for (uint256 i = 0; i < blockDif; ++i) {
            tokensToReward += tmpRewardsPerBlock;
            tmpRewardsPerBlock = tmpRewardsPerBlock.mulDiv(999, 1000, Math.Rounding.Up);
        }

        _rewardsPerBlock = tmpRewardsPerBlock;
        lottoRewardsToken.mint(msg.sender, tokensToReward);
    }

    function _safeBinarySearchDownExclusive(
        ERC80085.Snapshot[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        require(_array.length > 0, "Array is empty");
        uint256 result = _binarySearchDownExclusive(_array, _target, _low);
        require(result != 0xffffffffffffffff, "Target not found in array");
        return result;
    }

    function _safeBinarySearchDownExclusive(
        ERC80085.Snapshot[] memory _array,
        uint256 _target
    ) internal pure returns (uint256) {
        return _safeBinarySearchDownExclusive(_array, _target, 0);
    }

    function _safeBinarySearchUpExclusive(
        WinningInfoDAO[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        require(_array.length > 0, "Array is empty");
        uint256 result = _binarySearchUpExclusive(_array, _target, _low);
        require(result != _array.length, "Target not found in array");
        return result;
    }

    function _safeBinarySearchUpExclusive(
        WinningInfoDAO[] memory _array,
        uint256 _target
    ) internal pure returns (uint256) {
        return _safeBinarySearchUpExclusive(_array, _target, 0);
    }

    /**
     * @dev Returns the accumulated Ethereum balance for the specified account.
     * @param account The account for which the balance is queried.
     * @return eth accumulated Ethereum balance.
     */
    function _accEth(address account) private view returns (uint256 eth) {
        // get person whos accumulated ether we're checking
        ERC80085.Snapshot[] memory transactions = lottoRewardsToken.holderData(account).transferSnaps;

        // get array of winning/lottery information
        WinningInfoDAO[] memory winningHistory = _winningHistory;
        uint256 len = winningHistory.length;

        // make special case for first staked?

        // find startingPoint of the first lottery who's timestamp is after their first transaction
        uint256 startingPoint = _safeBinarySearchUpExclusive(winningHistory, transactions[0].blockNumber);

        // find the transaction that is closest to the start of that lottery
        uint256 txNum = _safeBinarySearchDownExclusive(transactions, winningHistory[startingPoint].blockNumber);

        // iterate through the lotteries
        while (startingPoint < len) {
            txNum = _safeBinarySearchDownExclusive(transactions, winningHistory[startingPoint].blockNumber, txNum);

            // calculate the amount of Ether accumulated during the current lottery
            eth += winningHistory[startingPoint].feeAmount.mulDiv(
                transactions[txNum].snapBalance,
                winningHistory[startingPoint].totalStakedSupply
            );
            // move to next lottery
            ++startingPoint;
        }
    }

    function _binarySearchDownExclusive(
        ERC80085.Snapshot[] memory _array,
        uint256 _target,
        uint256 _low
    ) private pure returns (uint256) {
        uint256 low = _low;
        unchecked {
            uint256 high = _array.length;
            while (low < high) {
                uint256 mid = (low + high) / 2;
                if (_array[mid].blockNumber >= _target) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            }
        }
        // Return the index of the number closest but less than the target number
        // or a special value if the target is not found
        if (low == 0) {
            return 0xffffffffffffffff;
        } else {
            return low - 1;
        }
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////

    function _binarySearchUpExclusive(
        WinningInfoDAO[] memory _array,
        uint256 _target,
        uint256 _low
    ) private pure returns (uint256) {
        unchecked {
            uint256 low = _low;
            uint256 high = _array.length;
            while (low < high) {
                uint256 mid = (low + high) >> 1;
                if (_array[mid].blockNumber <= _target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
            // Return the index of the number closest but greater than the target number
            return low;
        }
    }
}
