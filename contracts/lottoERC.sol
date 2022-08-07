// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC80085.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";


contract LottoERC is ERC20Permit, ERC80085 {

    // will be the lottery contract
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    constructor() ERC20("Lotto Token", "LT") ERC20Permit("Lotto Token") {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function startStaking() public onlyRole(MINTER_ROLE) {
        _startStaking(tx.origin);
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /// @notice transfer out some eth
    /// @dev this function makes transfering eth accessible to external people
    /// or contracts with `MINTER_ROLE` and will be used for withdrawing rewards
    /// @param to the lucky sole to get some eth
    /// @param amount the amount of eth to send
    function transferWinnings(address to, uint256 amount)
        public
        virtual
        onlyRole(MINTER_ROLE)
    {
        unchecked {
            _holders[to].rewardsWithdrawn += amount;
        }
        payable(to).transfer(amount);
    }

}