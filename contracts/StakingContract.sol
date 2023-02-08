// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**

TODO

[ ] check functions especially binary searches
[ ] can we make more bigger structs/maps to structs instead of a bunch of mappings
[ ] reentrency guards?
[ ] make sure flow works so I'm not giving them tokens/eth before i do whatever\
[ ] test binary search functions
[ ] make sure send is sending tokens not ether


 */
contract StakingContract is
    Context
    // Ownable
{
    using Math for uint256;

    struct Payouts {
        uint256 amount;
        uint256 totalStakedSupply;
        uint256 blockNumber;
    }

    struct Snapshot {
        uint256 blockNumber;
        uint256 tokensStaked;
    }

    uint256 private _totalCurrentlyStaked;

    mapping(address => Snapshot[]) private _playerSnaps;
    mapping(address => uint256) private _playerTokensStaked;
    mapping(address => uint256) private _playerEtherWithdrawn;

    Payouts[] private _payouts;

    ERC777 private _stakingToken;

    constructor(address erc777) {
        _stakingToken = ERC777(erc777);
        // _payouts.push();
    }

    function receivedPayout(uint256 value) external {
        _payouts.push(Payouts(value, _totalCurrentlyStaked, block.number));
    }

    // reentrency guard?
    function stake(uint256 tokensToStake) public {
        require(tokensToStake > 0, "staked tokens must be > 0");
        _stakingToken.operatorSend(_msgSender(), address(this), tokensToStake, "", "");
        _stake(tokensToStake, _msgSender());
    }

    function unstake(uint256 tokensToUnstake) public {
        require(tokensToUnstake > 0, "must unstake > 0 tokens");
        require(_playerTokensStaked[_msgSender()] - tokensToUnstake > 0, "unstaking too many tokens");
        _unstake(tokensToUnstake, _msgSender());
        _stakingToken.send(_msgSender(), tokensToUnstake, "");
    }

    function unstakeAll() public {
        require(_playerTokensStaked[_msgSender()] > 0, "have no tokens to unstake");
        _unstake(_playerTokensStaked[_msgSender()], _msgSender());
        _stakingToken.send(_msgSender(), _playerTokensStaked[_msgSender()], "");
    }

    function withdrawRewards(uint256 amount) public {
        require(amount > 0, "amount must be > 0");
        _withdrawRewards(_msgSender(), amount);
    }

    function withdrawAllRewards() public {
        _withdrawRewards(_msgSender(), 0);
    }

    function payoutList() public view returns (Payouts[] memory) {
        return _payouts;
    }

    function totalCurrentlyStaked() public view returns (uint256) {
        return _totalCurrentlyStaked;
    }

    function _stake(uint256 tokensToStake, address staker) private {
        _totalCurrentlyStaked += tokensToStake;
        _playerTokensStaked[staker] += tokensToStake;

        // or - need to move down in case this is first transaction
        // uint256 staked = _accountSnaps[staker][_accountSnaps[staker].length - 1].tokensStaked;
        // uint256 withdrawn = _accountSnaps[staker][_accountSnaps[staker].length - 1].etherWithdrawn;

        // or don't assign variables and just paste them in

        if (_playerSnaps[staker].length == 0) {
            _playerSnaps[staker].push(Snapshot(block.number, tokensToStake));
        } else {
            _playerSnaps[staker].push(Snapshot(block.number, _playerTokensStaked[staker]));
        }
    }

    function _unstake(uint256 tokensToUnstake, address staker) private {
        _playerTokensStaked[staker] -= tokensToUnstake;
        _totalCurrentlyStaked -= tokensToUnstake;

        if (_playerTokensStaked[staker] == 0) {
            delete _playerTokensStaked[staker];
        } else {
            _playerSnaps[staker].push(Snapshot(block.number, _playerTokensStaked[staker]));
        }
    }

    function _withdrawRewards(address account, uint256 amount) private {
        uint256 eth = _accEth(account) - _playerEtherWithdrawn[account];
        require(amount <= eth, "amount > available eth");
        if (amount == eth || amount == 0) {
            delete _playerSnaps[account];
            delete _playerEtherWithdrawn[account];
            payable(account).transfer(eth);
        } else {
            payable(account).transfer(amount);
        }
    }

    function _accEth(address account) private view returns (uint256 eth) {
        // get person whos accumulated ether we're checking
        Snapshot[] memory stakeHistory = _playerSnaps[account];

        // get array of winning/lottery information
        Payouts[] memory lottoHistory = _payouts;
        uint256 len = lottoHistory.length;

        // make special case for first staked?

        // find startingPoint of the first lottery who's timestamp is after their first transaction
        uint256 startingPoint = _binarySearchUpExclusive(lottoHistory, stakeHistory[0].blockNumber, 0);

        // find the transaction that is closest to the start of that lottery
        uint256 txNum = _binarySearchDownExclusive(stakeHistory, lottoHistory[startingPoint].blockNumber, 0);

        // iterate through the lotteries
        while (startingPoint < len) {
            txNum = _binarySearchDownExclusive(stakeHistory, lottoHistory[startingPoint].blockNumber, txNum);

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
        if (_low == 0) {
            return 0xffffffffffffffff;
        } else {
            return _low - 1;
        }
    }

    /* solhint-disable ordering, no-empty-blocks*/
    function tokensReceived(address, address from, address, uint256 amount, bytes calldata, bytes calldata) external {
        _stake(amount, from);
    }

    receive() external payable {}
    /* solhint-enable ordering, no-empty-blocks */
}
