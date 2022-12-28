    function _binarySearchDownExclusive(
        ERC80085.Snapshot[] memory _array,
        uint256 _target,
        uint256 _low
    ) private pure returns (uint256) {
        uint256 low = _low;
        uint256 high = _array.length;
        while (low < high) {
            uint256 mid = (low + high) >> 1;
            if (_array[mid].blockNumber >= _target) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        // Return the index of the number closest but less than the target number
        // or a special value if the target is not found
        if (low == 0) {
            return 0xffffffffffffffff;
        } else {
            return low - 1;
        }
    }

    function safeBinarySearchDownExclusive(
        ERC80085.Snapshot[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        require(_array.length > 0, "Array is empty");
        uint256 result = _binarySearchDownExclusive(_array, _target, _low);
        require(result != 0xffffffffffffffff, "Target not found in array");
        return result;
    }

    function safeBinarySearchDownExclusive(
        ERC80085.Snapshot[] memory _array,
        uint256 _target
    ) internal pure returns (uint256) {
        return safeBinarySearchDownExclusive(_array, _target, 0);
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////
    // Snapshot[] memory & WinningInfoDAO[] memory

    function _binarySearchUpExclusive(
        WinningInfoDAO[] memory _array,
        uint256 _target,
        uint256 _low
    ) private pure returns (uint256) {
        uint256 low = _low;
        uint256 high = _array.length;
        while (low < high) {
            uint256 mid = (low + high) >> 1;
            if (_array[mid].blockNumber <= _target) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        // Return the index of the number closest but greater than the target number
        return low;
    }

    function safeBinarySearchUpExclusive(
        WinningInfoDAO[] memory _array,
        uint256 _target,
        uint256 _low
    ) internal pure returns (uint256) {
        require(_array.length > 0, "Array is empty");
        uint256 result = _binarySearchUpExclusive(_array, _target, _low);
        require(result != _array.length, "Target not found in array");
        return result;
    }

    function safeBinarySearchUpExclusive(
        WinningInfoDAO[] memory _array,
        uint256 _target
    ) internal pure returns (uint256) {
        return safeBinarySearchUpExclusive(_array, _target, 0);
    }