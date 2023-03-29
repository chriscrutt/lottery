// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LottoV2.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**

TODO


[x] make more gas-efficient
[x] add ignore to functions mixed up because where they are placed right now makes it flow better
[x] add NatSpec
[ ] make some internal/private functions public?
[ ] emit something if beneficiary was swapped/added/removed. Do something if beneficiary doesn't exist


 */

abstract contract LottoGratuity is BasicLotto {
    using Math for uint256;

    // beneficiary data
    struct Beneficiary {
        address beneficiary;
        uint256 gratuity;
    }

    // list of beneficiaries
    Beneficiary[] private _beneficiaries;

    // total amount to be given to beneficiaries
    uint256 private _totalGratuity;

    /**
     * @notice sets up lottery with beneficiaries and starts it!
     * @param beneficiaries to get mulla
     * @param gratuityTimes1000 for each beneficiary
     * @param minPot_ minimum pot for lottery to end
     * @param lottoLength_ minimum block length for lottery to end
     * @param securityBeforeDraw_ blocks to wait before drawing for security
     * @param securityAfterDraw_ blocks to wait before payout for security
     */
    constructor(
        address[] memory beneficiaries,
        uint256[] memory gratuityTimes1000,
        uint256 minPot_,
        uint256 lottoLength_,
        uint256 securityBeforeDraw_,
        uint256 securityAfterDraw_
    ) BasicLotto(minPot_, lottoLength_, securityBeforeDraw_, securityAfterDraw_) {
        uint256 len = beneficiaries.length;
        require(len == gratuityTimes1000.length, "array length mismatch");
        for (uint256 i = 0; i < len; ++i) {
            require(beneficiaries[i] != address(0), "sending to 0 addy");
            _totalGratuity += gratuityTimes1000[i];
            require(_totalGratuity < 1000, "gratuity is (greater than) 100%");
            _beneficiaries.push(Beneficiary(beneficiaries[i], gratuityTimes1000[i]));
        }
    }

    /**
     * @dev adds a beneficiary and makes sure gratuity doesn't exceed max
     * @param beneficiary to be paid out
     * @param gratuity to be earned
     */
    function _addBeneficiary(address beneficiary, uint256 gratuity) internal {
        require(beneficiary != address(0), "can't be 0 address");
        require(_totalGratuity + gratuity < 1000, "gratuity is >= 100%");
        _totalGratuity += gratuity;
        _beneficiaries.push(Beneficiary(beneficiary, gratuity));
    }

    /**
     * @dev get rid of a beneficiary
     * @param beneficiary to be removed
     */
    function _removeBeneficiary(address beneficiary) internal {
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0; i < len; ++i) {
            if (_beneficiaries[i].beneficiary == beneficiary) {
                _totalGratuity -= _beneficiaries[i].gratuity;
                _beneficiaries[i] = _beneficiaries[--len];
                _beneficiaries.pop();
                break;
            }
        }
        revert("beneficiary doesn't exist");
    }

    /**
     * @dev pays out beneficiaries before lottery winner
     * @param amount is the initial pot
     */
    function _payout(uint256 amount) internal virtual override {
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0; i < len; ++i) {
            payable(_beneficiaries[i].beneficiary).transfer(amount.mulDiv(_beneficiaries[i].gratuity, 1000));
        }
        super._payout(address(this).balance);
    }

    /**
     * @dev swaps one beneficiary for another in case there is a beneficiary cap
     * @param oldBeneficiary to be removed
     * @param newBeneficiary to be added
     * @param newGratuity to be given
     */
    function _swapBeneficiary(address oldBeneficiary, address newBeneficiary, uint256 newGratuity) internal {
        require(newBeneficiary != address(0), "can't be 0 address");
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0; i < len; ++i) {
            if (_beneficiaries[i].beneficiary == oldBeneficiary) {
                _totalGratuity -= _beneficiaries[i].gratuity;
                _beneficiaries[i].beneficiary = newBeneficiary;
                _beneficiaries[i].gratuity = newGratuity;
                require(_totalGratuity + newGratuity < 1000, "gratuity is (greater than) 100%");
                _totalGratuity += newGratuity;
                break;
            }
        }
    }

    /**
     * @dev swaps one beneficiary for another in case there is a beneficiary cap
     * @param beneficiary to be removed
     * @param newGratuity to be given
     */
    function _changeGratuity(address beneficiary, uint256 newGratuity) internal {
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0; i < len; ++i) {
            if (_beneficiaries[i].beneficiary == beneficiary) {
                _totalGratuity -= _beneficiaries[i].gratuity;
                require(_totalGratuity + newGratuity < 1000, "gratuity is (greater than) 100%");
                _totalGratuity += newGratuity;
                break;
            }
        }
    }
}
