// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./LottoV2.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**

TODO


[x] make more gas-efficient
[ ] add ignore to functions mixed up because where they are placed right now makes it flow better
[ ] add NatSpec
[ ] make some internal/private functions public?
[ ] not worth it to deploy an entire library for one use unless lottoDAO uses it? Or just deploy on there then.


 */

abstract contract LottoGratuity is BasicLotto {
    using Math for uint256;

    struct Beneficiary {
        address beneficiary;
        uint256 gratuity;
    }

    Beneficiary[] private _beneficiaries;

    uint256 private _totalGratuity;

    constructor(
        address[] memory beneficiaries,
        uint256[] memory gratuityTimes1000,
        uint256 minPot_,
        uint256 lottoLength_
    ) BasicLotto(minPot_, lottoLength_) {
        uint256 len = beneficiaries.length;
        require(len == gratuityTimes1000.length, "array length mismatch");
        for (uint256 i = 0; i < len; ++i) {
            require(beneficiaries[i] != address(0), "sending to 0 addy");
            _totalGratuity += gratuityTimes1000[i];
            require(_totalGratuity < 1000, "gratuity is (greater than) 100%");
            _beneficiaries.push(Beneficiary(beneficiaries[i], gratuityTimes1000[i]));
        }
    }

    function _addBeneficiary(address beneficiary, uint256 gratuity) internal {
        require(beneficiary != address(0), "can't be 0 address");
        _totalGratuity += gratuity;
        require(_totalGratuity < 1000, "gratuity is (greater than) 100%");
        _beneficiaries.push(Beneficiary(beneficiary, gratuity));
    }

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
    }

    function _swapBeneficiary(address oldBeneficiary, address newBeneficiary, uint256 newGratuity) private {
        require(newBeneficiary != address(0), "can't be 0 address");
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0; i < len; ++i) {
            if (_beneficiaries[i].beneficiary == oldBeneficiary) {
                _totalGratuity -= _beneficiaries[i].gratuity;
                _beneficiaries[i].beneficiary = newBeneficiary;
                _beneficiaries[i].gratuity = newGratuity;
                _totalGratuity += newGratuity;
                require(_totalGratuity < 1000, "gratuity is (greater than) 100%");
                break;
            }
        }
    }

    function _payout(uint256 amount) internal virtual override {
        uint256 len = _beneficiaries.length;
        for (uint256 i = 0;
        i < len;
        ++i) {
            // uint256 mulla = balance.mulDiv(
            //             _beneficiaries[i].gratuity,
            //             1000
            //             );
            uint256 mulla = amount *
            _beneficiaries[i].gratuity /
            1000;
            payable(
                _beneficiaries[i].beneficiary
                ).transfer(mulla);
        }
        super._payout(address(this).balance);
    }
}
