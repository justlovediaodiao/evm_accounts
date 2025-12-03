// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Errors.sol";

/**
 * @title Ownable2Step
 * @notice Two-step ownership transfer pattern for enhanced security
 * @dev Prevents accidental ownership transfers to wrong addresses
 */
abstract contract Ownable2Step {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        if (_owner != msg.sender) {
            revert NotOwner();
        }
        _;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert InvalidAddress();
        }
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(_owner, newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer
     */
    function acceptOwnership() public virtual {
        if (msg.sender != _pendingOwner) {
            revert NotPendingOwner();
        }
        _transferOwnership(_pendingOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account
     * @param newOwner The address to transfer ownership to
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
