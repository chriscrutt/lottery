// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "./LottoSimplifiedExt.sol";
import "./lottoERC20.sol";

contract NewLotto {
    LottoToken public lottoToken;

    constructor() {
        lottoToken = new LottoToken();
    }
}
