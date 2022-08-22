// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/// @title An "special" ERC20 rewards token
/// @author Dr. Doofenshmirtz
/// @notice Withdraw Ethereum fee earnings through holding this token!
/// @dev Tokens are earned by helping (re)start the lottery after the previous
/// one ends. Token holders are rewarded with fees taken from lottery winners
/// and may withdraw Ethereum relative to their % makeup of the total supply.
/// TODO
/// see cheaper options
/// reorder functions
/// remove unneccessary
///     variables
///     functions
///     visibilities
///     imports (like math)
/// add comments
/// subtract before sending funds
/// see if loop runs out of gas
/// make sure ALL eth gets sent
/// is setting `fromBalance` variable worth it

abstract contract ERC80085 is ERC20, ERC20Permit {
    // logs each token transaction to help calculate withdrawable eth rewards
    struct Snapshot {
        uint256 blockNumber;
        uint256 snapBalance;
    }

    // keeps track of every token holder's balance and eth already withdrawn
    struct TokenHolder {
        Snapshot[] transferSnaps;
        uint256 rewardsWithdrawn;
        uint256 stakedOnBlock;
        uint256 balance;
    }

    // the total supply of tokens
    uint256 private _totalSupply;

    // the total supply of staked tokens
    uint256 private _totalStakedSupply;

    // a mapping of every token holder for easy lookup
    mapping(address => TokenHolder) private _holders;

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _holders[account].balance;
    }

    /// @notice transfer out some eth
    /// @dev this function makes transfering eth accessible to external people
    /// or contracts with `MINTER_ROLE` and will be used for withdrawing rewards
    /// @param to the lucky sole to get some eth
    /// @param amount the amount of eth to send
    function _transferEth(address to, uint256 amount) internal virtual {
        _holders[to].rewardsWithdrawn += amount;
        payable(to).transfer(amount);
    }

    /// @notice enables earning ethereum fee rewards
    /// @param account to enable staking for
    function _startStaking(address account) internal virtual {
        _holders[account].stakedOnBlock = block.number;

        _totalStakedSupply += balanceOf(account);
    }

    function holderData(address account)
        public
        view
        virtual
        returns (TokenHolder memory)
    {
        return _holders[account];
    }

    /// @dev makes total staked supply accessible from external contracts
    /// @return shows total staked supply of tokens
    function totalStakedSupply() public view virtual returns (uint256) {
        return _totalStakedSupply;
    }

    /// @notice transfers tokens from one person to another
    /// @dev unlike "normal" ERC20 tokens- LT token data is stored in structs.
    /// This makes it possible to create a snapshot of every transaction in
    /// order to calculate eth rewards for people who've held coins but not
    /// redeemed in a few rounds, or even transferred their coins before
    /// withdrawing
    /// @param from person who's transferring these tokens
    /// @param to person who's getting these tokens
    /// @param amount the amount of tokens to be sent * 10 ** -18
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "ERC20: send amount exceeds balance");
        unchecked {
            _logTokenTransaction(from, fromBalance - amount);
        }

        _updateStakedSupply(from, to, amount);

        _logTokenTransaction(to, balanceOf(to) + amount);

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /// @notice mints a certain amount of tokens to someone
    /// @dev same situation as `_transfer` in that info is stored in structs
    /// @param account person getting tokens minted to
    /// @param amount of tokens being minted * 10 ** -18
    function _mint(address account, uint256 amount) internal virtual override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _updateStakedSupply(address(0), account, amount);

        _logTokenTransaction(account, balanceOf(account) + amount);

        // _logTokenTransaction(account);
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /// @notice logs each token transaction
    /// @dev thought it'd be prettier to make a function instead of writing this
    /// out for both `_transfer` and `_mint`. This takes a snapshot of the block
    /// number and new balance for posterity and calculating eth rewards
    /// @param account the person we are logging the transaction for
    function _logTokenTransaction(address account, uint256 amount) private {
        _holders[account].transferSnaps.push(
            Snapshot({blockNumber: block.number, snapBalance: amount})
        );
        _holders[account].balance = amount;
    }

    /// @notice adjusts `_totalStakedSupply` according to whether tokens are
    /// being transferred to or from an account that has staking enabled
    /// @dev if `from` is enabled and `to` isn't, remove tokens from staked
    /// supply. if `from` isn't enabled and `to` is, add tokens from staked
    /// supply. in any other case, staked supply stays the same.
    /// @param from whom the tokens are being sent
    /// @param to whom the tokens are being sent
    /// @param amount of tokens * 10 ** -18 to be sent
    function _updateStakedSupply(
        address from,
        address to,
        uint256 amount
    ) private {
        if (_holders[from].stakedOnBlock > 0) {
            if (_holders[to].stakedOnBlock == 0) {
                unchecked {
                    _totalStakedSupply -= amount;
                }
            }
        } else {
            if (_holders[to].stakedOnBlock > 0) {
                _totalStakedSupply += amount;
            }
        }
    }

    function _updateWithdrawals(address account, uint256 amount) internal {
        unchecked {
            _holders[account].rewardsWithdrawn += amount;
        }
    }
}
