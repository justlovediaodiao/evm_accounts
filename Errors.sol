// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title Custom Errors
 * @notice Defines custom errors for gas-efficient error handling
 */

// Common errors
error InvalidAddress();
error Unauthorized();
error InvalidInput();
error TransferFailed();
error InsufficientBalance();
error ArrayLengthMismatch();
error ArrayTooLarge(uint256 length, uint256 maxLength);
error EmptyArray();

// Ownership errors
error NotOwner();
error NotPendingOwner();
error AlreadyOwner();

// Reentrancy errors
error ReentrantCall();

// ERC20 errors
error ERC20TransferFailed();
error ERC20ApprovalFailed();

// Contract call errors
error ContractCallFailed();
error InvalidFunctionSelector();
