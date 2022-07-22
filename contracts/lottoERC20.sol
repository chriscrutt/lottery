// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title An "special" ERC20 rewards token
/// @author Dr. Doofenshmirtz
/// @notice Withdraw Ethereum fee earnings through holding this token!
/// @dev Tokens are earned by helping (re)start the lottery after the previous
/// one ends. Token holders are rewarded with fees taken from lottery winners
/// and may withdraw Ethereum relative to their % makeup of the total supply.
/// TODO
/// [ ] maybe change `MINTER_ROLE` from public to private
/// [ ] figure out `DEFAULT_ADMIN_ROLE` - tx.origin?
/// [ ] just enabled minter only for transferWinnings- make sure it didn't break
/// [ ] `_beforeTokenTransfer` might not be needed anymore
/// [ ] only earn when staking? That way money on exchanges/MMs wont lose eth
/// [ ] commented a few things out hopefully they weren't needed
contract LottoToken is ERC20, AccessControl, ERC20Permit {
    // logs each token transaction to help calculate withdrawable eth rewards
    struct Snapshot {
        uint256 blockNumber;
        uint256 snapBalance;
    }

    // probably convoluted but yeah
    struct StakingInfo {
        bool isStaking;
        uint256 startedOnBlock;
    }

    // keeps track of every token holder's balance and eth already withdrawn
    struct TokenHolder {
        uint256 currentBalance;
        Snapshot[] transferSnaps;
        uint256 rewardsWithdrawn;
        StakingInfo stakingInfo;
    }

    // creating the minter role which will be the creator of this smart contract
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // a mapping of every token holder for easy lookup
    mapping(address => TokenHolder) private _holders;

    // the total supply of tokens
    uint256 private _totalSupply;

    // the total supply of staked tokens
    uint256 private _totalStakedSupply;

    /// creates permittable token with minting role set to contract creator
    constructor() ERC20("LottoToken", "LT") ERC20Permit("LottoToken") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /// @notice allows this contract to be sent Eth
    receive() external payable {}

    /// @notice mints coins
    /// @dev must be the assigned minter
    /// @param to the person to mint to
    /// @param amount the amount to mint * 10 ** -18
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @notice transfer out some eth
    /// @dev this function makes transfering eth accessible to external people
    /// or contracts with `MINTER_ROLE` and will be used for withdrawing rewards
    /// @param to the lucky sole to get some eth
    /// @param amount the amount of eth to send
    function transferWinnings(address to, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        payable(to).transfer(amount);
    }

    /// @notice allows external contracts to update ethereum rewards withdrawn
    /// @param account that's gonna be updated
    /// @param amount of wei they've just withdrawn
    function updateWithdrawals(address account, uint256 amount)
        public
        onlyRole(MINTER_ROLE)
    {
        _holders[account].rewardsWithdrawn += amount;
    }

    /// @notice enables earning ethereum fee rewards
    /// @param account to enable staking for
    function enableRewards(address account) public {
        require(tx.origin == account, "not your account homie");

        _holders[account].stakingInfo = StakingInfo({
            isStaking: true,
            startedOnBlock: block.number
        });

        _totalStakedSupply += _holders[account].currentBalance;
    }

    /// @notice checks to see if ethereum lotto rewards are enabled
    /// @param account to check
    function areRewardsEnabled(address account) public view returns (bool) {
        return _holders[account].stakingInfo.isStaking;
    }

    /// @param account the token holder
    /// @return current token balance of someone
    function balanceOf(address account) public view override returns (uint256) {
        return _holders[account].currentBalance;
    }

    function holderData(address account)
        public
        view
        returns (TokenHolder memory)
    {
        return _holders[account];
    }

    /// @dev makes total supply accessible from external contracts
    /// @return shows total supply of tokens
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @dev makes total staked supply accessible from external contracts
    /// @return shows total staked supply of tokens
    function totalStakedSupply() public view returns (uint256) {
        return _totalStakedSupply;
    }

    /// @dev not sure if this is needed anymore?
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
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
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balanceOf(from);
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _holders[from].currentBalance = fromBalance - amount;
            _logTokenTransaction(from);
        }

        _checkStakedSupply(from, to, amount);

        _holders[to].currentBalance += amount;
        _logTokenTransaction(to);

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /// @notice mints a certain amount of tokens to someone
    /// @dev same situation as `_transfer` in that info is stored in structs
    /// @param account person getting tokens minted to
    /// @param amount of tokens being minted * 10 ** -18
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;

        _checkStakedSupply(address(0), account, amount);

        _holders[account].currentBalance += amount;
        _logTokenTransaction(account);

        // _logTokenTransaction(account);
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /// @notice adjusts `_totalStakedSupply` according to whether tokens are
    /// being transferred to or from an account that has staking enabled
    /// @dev if `from` is enabled and `to` isn't, remove tokens from staked
    /// supply. if `from` isn't enabled and `to` is, add tokens from staked
    /// supply. in any other case, staked supply stays the same.
    /// @param from whom the tokens are being sent
    /// @param to whom the tokens are being sent
    /// @param amount of tokens * 10 ** -18 to be sent
    function _checkStakedSupply(
        address from,
        address to,
        uint256 amount
    ) private {
        if (areRewardsEnabled(from)) {
            if (!areRewardsEnabled(to)) {
                _totalStakedSupply -= amount;
            }
        } else {
            if (areRewardsEnabled(to)) {
                _totalStakedSupply += amount;
            }
        }
    }

    /// @notice logs each token transaction
    /// @dev thought it'd be prettier to make a function instead of writing this
    /// out for both `_transfer` and `_mint`. This takes a snapshot of the block
    /// number and new balance for posterity and calculating eth rewards
    /// @param account the person we are logging the transaction for
    function _logTokenTransaction(address account) private {
        _holders[account].transferSnaps.push(
            Snapshot({
                blockNumber: block.number,
                snapBalance: balanceOf(account)
            })
        );
    }
}
