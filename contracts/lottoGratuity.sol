// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./lotto.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title LottoGratuity
 * @dev A lotto contract that allows the creator to specify a number of beneficiaries who will
 * receive a percentage of the winnings as gratuity.
 */

abstract contract LottoGratuity is Lotto {
    using Math for uint256;

    // Struct representing a beneficiary.
    struct Beneficiary {
        address beneficiary;
        uint256 gratuity; //The gratuity percentage for the beneficiary * 1000
    }

    uint256 private _gratuitiesSum;

    uint8 private _maxBeneficiaries;

    Beneficiary[] private _beneficiaries;

    /**
     * @dev Constructor for the contract.
     * @param maxBeneficiaries_ The maximum number of beneficiaries allowed.
     * @param beneficiary The first beneficiary to be added.
     * @param gratuity The gratuity percentage for the first beneficiary.
     */
    constructor(
        uint8 maxBeneficiaries_,
        address beneficiary,
        uint256 gratuity
    ) {
        require(maxBeneficiaries_ > 0, "need to be more than 1 bene");
        _maxBeneficiaries = maxBeneficiaries_;
        if (beneficiary != address(0)) {
            _addBeneficiary(beneficiary, gratuity);
        }
    }

    /**
     * @notice Swaps the beneficiary for a given beneficiary number.
     * @param beneficiaryNumber The number of the beneficiary to swap.
     * @param beneficiary The new beneficiary address.
     * @param gratuity The gratuity to be paid to the new beneficiary.
     */
    function swapBeneficiary(
        uint256 beneficiaryNumber,
        address beneficiary,
        uint256 gratuity
    ) public virtual {
        _swapBeneficiary(beneficiaryNumber, beneficiary, gratuity);
    }

    function beneficiaryGratuity() public view returns (Beneficiary[] memory) {
        return _beneficiaries;
    }

    function beneficiarySpotsLeft() public view returns (uint256) {
        return _maxBeneficiaries;
    }

    /**
     * @notice Add a beneficiary to the contract
     * @param beneficiary The address of the beneficiary to be added
     * @param gratuity The amount of gratuity to be given to the beneficiary
     * @dev This function adds a beneficiary to the contract and updates the gratuity sum. It will
     * revert if the maximum number of beneficiaries has already been reached or if the gratuity
     * sum would exceed 1000.
     */
    function _addBeneficiary(
        address beneficiary,
        uint256 gratuity
    ) internal virtual {
        require(_maxBeneficiaries != 0, "max beneficiaries added");
        require(beneficiary != address(0), "cant be 0 address");
        uint256 tmpGratutiesSum = _gratuitiesSum + gratuity;
        require(tmpGratutiesSum < 1000, "gratuity too great");
        _gratuitiesSum = tmpGratutiesSum;
        _maxBeneficiaries--;

        _beneficiaries.push(
            Beneficiary({ beneficiary: beneficiary, gratuity: gratuity })
        );
    }

    /**
     * @notice Swaps the beneficiary for a given beneficiary number.
     * @param beneficiaryNumber The number of the beneficiary to swap.
     * @param beneficiary The new beneficiary address.
     * @param gratuity The gratuity to be paid to the new beneficiary.
     * @dev This function swaps the beneficiary for a given beneficiary number. It requires that
     * the caller is the current beneficiary, and that the new beneficiary is not the zero address.
     * It also requires that the sum of the gratuities does not exceed 1000.
     */
    function _swapBeneficiary(
        uint256 beneficiaryNumber,
        address beneficiary,
        uint256 gratuity
    ) internal virtual {
        Beneficiary memory tmpBene = beneficiaryGratuity()[beneficiaryNumber];
        require(tmpBene.beneficiary == _msgSender(), "only current can swap");
        require(beneficiary != address(0), "must not be 0 address");
        uint256 tmpGratuitiesSum = _gratuitiesSum - tmpBene.gratuity + gratuity;
        require(tmpGratuitiesSum < 1000, "sum of gratuities is >= 1000");
        _gratuitiesSum = tmpGratuitiesSum;
        _beneficiaries[beneficiaryNumber].beneficiary = beneficiary;
        _beneficiaries[beneficiaryNumber].gratuity = gratuity;
    }

    /**
     * @dev Pays out a given amount to the beneficiaries based on their gratuity percentage.
     * @param amount The amount to be paid out.
     */
    function _payout(uint256 amount) internal virtual override {
        Beneficiary[] memory tempBene = _beneficiaries;
        uint256 len = tempBene.length;
        for (uint256 i = 0; i < len; ++i) {
            if (tempBene[i].gratuity > 0) {
                payable(tempBene[i].beneficiary).transfer(
                    amount.mulDiv(tempBene[i].gratuity, 1000)
                );
            }
        }

        super._payout(address(this).balance);
    }
}
