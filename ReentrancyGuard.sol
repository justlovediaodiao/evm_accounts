// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Errors.sol";

/**
 * @title ReentrancyGuard
 * @notice Prevents reentrant calls to a function
 * @dev Uses a simple lock pattern with custom errors for gas efficiency
 */
abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly
     */
    modifier nonReentrant() {
        if (_status == ENTERED) {
            revert ReentrantCall();
        }
        _status = ENTERED;
        _;
        _status = NOT_ENTERED;
    }
}
