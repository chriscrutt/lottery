// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IStakingContract.sol";

/**

TODO

[-] (run in remix) check functions especially binary searches
[x] can we make more bigger structs/maps to structs instead of a bunch of mappings
[x] reentrency guards?
[x] make sure flow works so I'm not giving them tokens/eth before i do whatever\
[x] make sure send is sending tokens not ether
[-] make ownable/whatever for receivedPayout cause only lottoDAO should be calling that (i think)
[x] make sure not deleting things that shouldn't be deleted
[-] gas-efficiency
[-] make .send .transfer maybe
[x] make sure only owners of their addresses can withdraw eth/stake
[-] (run in remix) if withdrawing all, delete history to clear up storage- not if unstaking all
[x] when to make functions public, external, private, internal - receivedPayout??? tokensReceived???
[x] change lotto payout to having the lottery contract call it
[x] cant delete snapshots cause rely on it for acc eth


 */
contract StakingContract is Context, ReentrancyGuard, Ownable, IStakingContract {
    using Math for uint256;
    using SafeERC20 for IERC20;

    // snapshot of last token transfer
    struct Snapshot {
        uint256 blockNumber;
        uint256 tokensStaked;
    }

    // the player in question
    struct Player {
        Snapshot[] snapshots;
        uint256 tokensStaked;
        uint256 etherWithdrawn;
    }

    // total tokens staked
    uint256 private _totalCurrentlyStaked;

    // maps address to player
    mapping(address => Player) private _players;

    // array of payouts
    Payouts[] private _payouts;

    // designate the staking/rewards token
    IERC20 public stakingToken;

    /**
     * @param erc20 designates staking/rewards token
     */
    constructor(address erc20) {
        stakingToken = IERC20(erc20);
        // _payouts.push();
    }

    receive() external payable virtual override onlyOwner {
        _receivedLottoPayout();
    }

    /**
     * @notice stakes tokens
     * @param tokensToStake tokens to stake
     */
    function stake(uint256 tokensToStake) public virtual override nonReentrant returns (bool) {
        require(tokensToStake > 0, "staked tokens must be > 0");
        stakingToken.safeTransferFrom(_msgSender(), address(this), tokensToStake);
        _stake(tokensToStake, _msgSender());

        return true;
    }

    /**
     * @notice unstakes tokens
     * @param tokensToUnstake tokens to unstake
     */
    function unstake(uint256 tokensToUnstake) public virtual override nonReentrant returns (bool) {
        require(tokensToUnstake > 0, "must unstake > 0 tokens");
        require(
            _players[_msgSender()].tokensStaked >= tokensToUnstake,
            "unstaking too many tokens"
        );
        _unstake(tokensToUnstake, _msgSender());
        stakingToken.safeTransfer(_msgSender(), tokensToUnstake);

        return true;
    }

    /**
     * @notice withdraws available ether rewards
     * @param amount ether to claim
     */
    function withdrawRewards(uint256 amount) public virtual override nonReentrant returns (bool) {
        require(amount > 0, "amount must be > 0");
        _withdrawRewards(_msgSender(), amount);

        return true;
    }

    /**
     * @notice returns array of lottery payouts
     */
    function payoutInfo(uint256 id) public view virtual override returns (Payouts memory) {
        return _payouts[id];
    }

    /**
     * @notice returns total amount of tokens staked
     */
    function totalCurrentlyStaked() public view virtual override returns (uint256) {
        return _totalCurrentlyStaked;
    }

    /**
     * @notice returns total amount of ether available to withdraw
     */
    function withdrawableEth(address account) public view virtual override returns (uint256) {
        return _accEth(account) - _players[account].etherWithdrawn;
    }

    /**
     * @notice push lotto payout data to array
     */
    function _receivedLottoPayout() internal virtual {
        _payouts.push(Payouts(msg.value, _totalCurrentlyStaked, block.number));
    }

    /**
     * @dev adds tokens staked to total staked and player's staked in snapshot
     * @param tokensToStake tokens to stake
     * @param staker tokens to unstake
     */
    function _stake(uint256 tokensToStake, address staker) internal virtual {
        unchecked {
            _totalCurrentlyStaked += tokensToStake;
            _players[staker].tokensStaked += tokensToStake;
        }
        _players[staker].snapshots.push(Snapshot(block.number, _players[staker].tokensStaked));
        emit Stake(staker, tokensToStake);
    }

    /**
     * @dev subs tokens staked from total staked and player's staked in snapshot
     * @param tokensToUnstake tokens to unstake
     * @param staker tokens to unstake
     */
    function _unstake(uint256 tokensToUnstake, address staker) internal virtual {
        unchecked {
            _players[staker].tokensStaked -= tokensToUnstake;
            _totalCurrentlyStaked -= tokensToUnstake;
        }
        _players[staker].snapshots.push(Snapshot(block.number, _players[staker].tokensStaked));
        emit Unstake(staker, tokensToUnstake);
    }

    /**
     * @dev subs eth from total available
     * @param account to withdraw eth
     * @param amount tokens to unstake
     */
    function _withdrawRewards(address account, uint256 amount) internal virtual {
        unchecked {
            uint256 eth = withdrawableEth(account);
            require(amount <= eth, "amount > available eth");

            if (amount == eth) {
                delete _players[account].snapshots;
                _players[account].snapshots.push(
                    Snapshot(block.number, _players[account].tokensStaked)
                );
                _players[account].etherWithdrawn = 0;
            } else {
                _players[account].etherWithdrawn += amount;
            }
        }
        require(payable(account).send(amount), "eth transfer failed");
        emit WithdrawRewards(account, amount);
    }

    function _accEth(address account) private view returns (uint256 eth) {
        // get person whos accumulated ether we're checking
        Snapshot[] memory stakeHistory = _players[account].snapshots;

        // get array of winning/lottery information
        Payouts[] memory lottoHistory = _payouts;
        uint256 len = lottoHistory.length;

        // make special case for first staked?

        // find startingPoint of the first lottery who's timestamp is after their first transaction
        uint256 startingPoint = _binarySearchUpExclusive(
            lottoHistory,
            stakeHistory[0].blockNumber,
            0
        );

        // find the transaction that is closest to the start of that lottery
        uint256 txNum = _binarySearchDownExclusive(
            stakeHistory,
            lottoHistory[startingPoint].blockNumber,
            0
        );
        require(txNum < type(uint256).max, "tx not found");

        // iterate through the lotteries
        while (startingPoint < len) {
            txNum = _binarySearchDownExclusive(
                stakeHistory,
                lottoHistory[startingPoint].blockNumber,
                txNum
            );

            // calculate the amount of Ether accumulated during the current lottery
            eth += lottoHistory[startingPoint].amount.mulDiv(
                stakeHistory[txNum].tokensStaked,
                lottoHistory[startingPoint].totalStakedSupply
            );
            // move to next lottery
            ++startingPoint;
        }
    }

    function _binarySearchUpExclusive(
        Payouts[] memory _array,
        uint256 _target,
        uint256 _low
    ) private pure returns (uint256) {
        unchecked {
            // uint256 low = _low;
            uint256 high = _array.length;
            while (_low < high) {
                uint256 mid = (_low + high) >> 1;
                if (_array[mid].blockNumber <= _target) {
                    _low = mid + 1;
                } else {
                    high = mid;
                }
            }
            // Return the index of the number closest but greater than the target number
            return _low;
        }
    }

    function _binarySearchDownExclusive(
        Snapshot[] memory _array,
        uint256 _target,
        uint256 _low
    ) private pure returns (uint256) {
        // uint256 low = _low;
        unchecked {
            uint256 high = _array.length;
            while (_low < high) {
                uint256 mid = (_low + high) / 2;
                if (_array[mid].blockNumber >= _target) {
                    high = mid;
                } else {
                    _low = mid + 1;
                }
            }
        }
        // Return the index of the number closest but less than the target number
        // or a special value if the target is not found
        if (_low != 0) {
            return _low - 1;
        } else {
            return type(uint256).max;
        }

        // revert("target not found");
    }

    // /* solhint-disable ordering*/
    // // function tokensReceived(
    // //     address,
    // //     address from,
    // //     address,
    // //     uint256 amount,
    // //     bytes calldata,
    // //     bytes calldata
    // // ) external {
    // //     require(amount > 0, "amount must be > 0");
    // //     _stake(amount, from);
    // // }

    /* solhint-enable ordering */
}
