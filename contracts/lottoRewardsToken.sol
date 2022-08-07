// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC80085.sol";

contract LottoRewardsToken is ERC80085 {
    // will be the lottery contract
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor()
        ERC20("Lotto Rewards Token", "LT")
        ERC20Permit("Lotto Rewards Token")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _grantRole(MINTER_ROLE, _msgSender());
    }

    function startStaking() public {
        _startStaking(_msgSender());
    }
}