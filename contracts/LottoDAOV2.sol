// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./LottoGratuityV2.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract LottoDAOV2 is Context {
    struct Snapshot {
        uint256 blockNumber;
        uint256 tokensStaked;
        uint256 etherWithdrawn;
    }

    address private _stakeableToken;

    mapping(address => Snapshot[]) private _accountSnaps;

    function deposit(uint256 tokensToStake) public {
        IERC777(_stakeableToken).operatorSend(_msgSender(), address(this), tokensToStake, "", "");
        _deposit(tokensToStake, _msgSender());
    }

    function _deposit(uint256 tokensToStake, address staker) private {
        // may be better than calling that mumbo jumbo twice
        Snapshot memory snap = _accountSnaps[staker][_accountSnaps[staker].length - 1];

        if (_accountSnaps[staker].length == 0) {
            _accountSnaps[staker].push(Snapshot(block.number, tokensToStake, 0));
        } else {
            _accountSnaps[staker].push(
                Snapshot(block.number, snap.tokensStaked + tokensToStake, snap.etherWithdrawn)
            );
        }
    }

    function withdrawableEth() public view returns (uint256) {

    }
}
