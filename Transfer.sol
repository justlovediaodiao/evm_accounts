// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./ReentrancyGuard.sol";
import "./Errors.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title Transfer
 * @notice Batch transfer ETH or ERC20 tokens to multiple addresses
 * @dev Implements gas-efficient batch operations with failure handling
 */
contract Transfer is ReentrancyGuard {
    // Maximum recipients that can be processed in a single batch
    uint256 public constant MAX_BATCH_SIZE = 100;

    // Events
    event BatchETHTransferCompleted(uint256 successCount, uint256 totalCount, uint256 totalAmount);
    event BatchERC20TransferCompleted(
        address indexed token,
        uint256 successCount,
        uint256 totalCount,
        uint256 totalAmount
    );
    event TransferFailed(address indexed recipient, uint256 amount, string reason);

    /**
     * @notice Batch transfer same amount of ETH to multiple recipients
     * @param recipients Array of recipient addresses
     * @param amount Amount of ETH to send to each recipient
     */
    function transfer(address payable[] memory recipients, uint256 amount)
        external
        payable
        nonReentrant
    {
        if (recipients.length == 0) revert EmptyArray();
        if (recipients.length > MAX_BATCH_SIZE) revert ArrayTooLarge(recipients.length, MAX_BATCH_SIZE);

        uint256 totalRequired = amount * recipients.length;
        if (msg.value != totalRequired) revert InvalidInput();

        uint256 successCount = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                emit TransferFailed(recipients[i], amount, "Invalid address");
                continue;
            }

            (bool success, ) = recipients[i].call{value: amount, gas: 50000}("");
            if (success) {
                successCount++;
            } else {
                emit TransferFailed(recipients[i], amount, "Transfer failed");
            }
        }

        emit BatchETHTransferCompleted(successCount, recipients.length, amount * successCount);

        // Refund any remaining ETH (from failed transfers)
        uint256 remaining = address(this).balance;
        if (remaining > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: remaining}("");
            if (!refundSuccess) revert TransferFailed();
        }
    }

    /**
     * @notice Batch transfer different amounts of ETH to multiple recipients
     * @param recipients Array of recipient addresses
     * @param amounts Array of ETH amounts to send to each recipient
     */
    function transferN(address payable[] memory recipients, uint256[] memory amounts)
        external
        payable
        nonReentrant
    {
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();
        if (recipients.length == 0) revert EmptyArray();
        if (recipients.length > MAX_BATCH_SIZE) revert ArrayTooLarge(recipients.length, MAX_BATCH_SIZE);

        uint256 totalRequired = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalRequired += amounts[i];
        }

        if (msg.value != totalRequired) revert InvalidInput();

        uint256 successCount = 0;
        uint256 totalTransferred = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                emit TransferFailed(recipients[i], amounts[i], "Invalid address");
                continue;
            }

            if (amounts[i] == 0) {
                continue;
            }

            (bool success, ) = recipients[i].call{value: amounts[i], gas: 50000}("");
            if (success) {
                successCount++;
                totalTransferred += amounts[i];
            } else {
                emit TransferFailed(recipients[i], amounts[i], "Transfer failed");
            }
        }

        emit BatchETHTransferCompleted(successCount, recipients.length, totalTransferred);

        // Refund any remaining ETH (from failed transfers)
        uint256 remaining = address(this).balance;
        if (remaining > 0) {
            (bool refundSuccess, ) = msg.sender.call{value: remaining}("");
            if (!refundSuccess) revert TransferFailed();
        }
    }

    /**
     * @notice Batch transfer same amount of ERC20 tokens to multiple recipients
     * @param tokenAddress ERC20 token contract address
     * @param recipients Array of recipient addresses
     * @param amount Amount of tokens to send to each recipient
     */
    function transferERC20(
        address tokenAddress,
        address[] memory recipients,
        uint256 amount
    ) external nonReentrant {
        if (recipients.length == 0) revert EmptyArray();
        if (recipients.length > MAX_BATCH_SIZE) revert ArrayTooLarge(recipients.length, MAX_BATCH_SIZE);
        if (tokenAddress == address(0)) revert InvalidAddress();

        IERC20 token = IERC20(tokenAddress);
        uint256 successCount = 0;
        uint256 totalTransferred = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                emit TransferFailed(recipients[i], amount, "Invalid address");
                continue;
            }

            try token.transferFrom(msg.sender, recipients[i], amount) returns (bool success) {
                if (success) {
                    successCount++;
                    totalTransferred += amount;
                } else {
                    emit TransferFailed(recipients[i], amount, "ERC20 transfer returned false");
                }
            } catch Error(string memory reason) {
                emit TransferFailed(recipients[i], amount, reason);
            } catch {
                emit TransferFailed(recipients[i], amount, "Unknown error");
            }
        }

        emit BatchERC20TransferCompleted(tokenAddress, successCount, recipients.length, totalTransferred);
    }

    /**
     * @notice Batch transfer different amounts of ERC20 tokens to multiple recipients
     * @param tokenAddress ERC20 token contract address
     * @param recipients Array of recipient addresses
     * @param amounts Array of token amounts to send to each recipient
     */
    function transferERC20N(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory amounts
    ) external nonReentrant {
        if (recipients.length != amounts.length) revert ArrayLengthMismatch();
        if (recipients.length == 0) revert EmptyArray();
        if (recipients.length > MAX_BATCH_SIZE) revert ArrayTooLarge(recipients.length, MAX_BATCH_SIZE);
        if (tokenAddress == address(0)) revert InvalidAddress();

        IERC20 token = IERC20(tokenAddress);
        uint256 successCount = 0;
        uint256 totalTransferred = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            if (recipients[i] == address(0)) {
                emit TransferFailed(recipients[i], amounts[i], "Invalid address");
                continue;
            }

            if (amounts[i] == 0) {
                continue;
            }

            try token.transferFrom(msg.sender, recipients[i], amounts[i]) returns (bool success) {
                if (success) {
                    successCount++;
                    totalTransferred += amounts[i];
                } else {
                    emit TransferFailed(recipients[i], amounts[i], "ERC20 transfer returned false");
                }
            } catch Error(string memory reason) {
                emit TransferFailed(recipients[i], amounts[i], reason);
            } catch {
                emit TransferFailed(recipients[i], amounts[i], "Unknown error");
            }
        }

        emit BatchERC20TransferCompleted(tokenAddress, successCount, recipients.length, totalTransferred);
    }
}
