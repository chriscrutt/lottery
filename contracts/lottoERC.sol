// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./ERC80085.sol";

contract LottoERC is ERC80085 {
        constructor() ERC20("Lotto Token", "LT") ERC20Permit("Lotto Token") {}

    function startStaking() public onlyRole(MINTER_ROLE) {
        _startStaking(tx.origin);
    }

    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

}