// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library BinarySearch {
    // enum Target {
    //     Strict, // Must be target
    //     CloseExclusive,
    //     CloseInclusive, // must be close to target
    //     UpExclusive, // Must be above target
    //     UpInclusive,
    //     DownExclusive, // Must be below target
    //     DownInclusive
    // }

    function _binarySearchDownExclusive(
        uint256[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        uint256 low = _low;
        unchecked {
            
        uint256 high = _array.length;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (_array[mid] >= _target) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }}
        // Return the index of the number closest but less than the target number
        // or a special value if the target is not found
        if (low == 0) {
            return 0xffffffffffffffff;
        } else {
            return low - 1;
        }
    }

    function safeBinarySearchDownExclusive(
        uint256[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        require(_array.length > 0, "Array is empty");
        uint256 result = _binarySearchDownExclusive(_array, _target, _low);
        require(result != 0xffffffffffffffff, "Target not found in array");
        return result;
    }

    function safeBinarySearchDownExclusive(
        uint256[] memory _array,
        uint256 _target
    ) internal pure returns (uint256) {
        return safeBinarySearchDownExclusive(_array, _target, 0);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////

    function _binarySearchUpExclusive(
        uint256[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        unchecked {
            
        
        uint256 low = _low;
        uint256 high = _array.length;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (_array[mid] <= _target) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        // Return the index of the number closest but greater than the target number
        return low;}
    }

    function safeBinarySearchUpExclusive(
        uint256[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        require(_array.length > 0, "Array is empty");
        uint256 result = _binarySearchUpExclusive(_array, _target, _low);
        require(result != _array.length, "Target not found in array");
        return result;
    }

    function safeBinarySearchUpExclusive(
        uint256[] memory _array,
        uint256 _target
    ) internal pure returns (uint256) {
        return safeBinarySearchUpExclusive(_array, _target, 0);
    }
}
