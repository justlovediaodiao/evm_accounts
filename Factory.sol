// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./account.sol";
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./Errors.sol";

/**
 * @title Factory
 * @notice Batch manages Account contracts with enhanced security
 * @dev Implements gas-efficient batch operations with failure handling
 */
contract Factory is Ownable2Step, ReentrancyGuard {
    // Maximum accounts that can be processed in a single batch operation
    uint256 public constant MAX_BATCH_SIZE = 100;

    // Events
    event AccountCreated(address indexed account, address indexed creator);
    event BatchTransferCompleted(uint256 successCount, uint256 totalCount);
    event TransferFailed(address indexed account, address indexed to, string reason);

    /**
     * @notice Create a single new Account contract
     * @return account Address of the newly created account
     */
    function createAccount() external onlyOwner returns (address account) {
        Account newAccount = new Account();
        account = address(newAccount);
        
        emit AccountCreated(account, msg.sender);
    }

    /**
     * @notice Create multiple Account contracts in a single transaction
     * @param count Number of accounts to create
     * @return newAccounts Array of newly created account addresses
     */
    function createAccounts(uint256 count) 
        external 
        onlyOwner 
        returns (address[] memory newAccounts) 
    {
        if (count == 0) revert EmptyArray();
        if (count > MAX_BATCH_SIZE) revert ArrayTooLarge(count, MAX_BATCH_SIZE);

        newAccounts = new address[](count);
        
        for (uint256 i = 0; i < count; i++) {
            Account newAccount = new Account();
            newAccounts[i] = address(newAccount);
            emit AccountCreated(newAccounts[i], msg.sender);
        }
    }

    /**
     * @notice Batch transfer ETH from multiple accounts
     * @param accounts Array of account addresses to transfer from
     * @param amounts Array of amounts to transfer from each account
     * @param to Recipient address
     */
    function transfer(
        address[] memory accounts,
        uint256[] memory amounts,
        address payable to
    ) external onlyOwner nonReentrant {
        if (accounts.length != amounts.length) revert ArrayLengthMismatch();
        if (accounts.length == 0) revert EmptyArray();
        if (accounts.length > MAX_BATCH_SIZE) revert ArrayTooLarge(accounts.length, MAX_BATCH_SIZE);
        if (to == address(0)) revert InvalidAddress();

        uint256 successCount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) {
                emit TransferFailed(accounts[i], to, "Invalid account address");
                continue;
            }

            try IAccount(accounts[i]).transfer(to, amounts[i]) {
                successCount++;
            } catch Error(string memory reason) {
                emit TransferFailed(accounts[i], to, reason);
            } catch {
                emit TransferFailed(accounts[i], to, "Unknown error");
            }
        }

        emit BatchTransferCompleted(successCount, accounts.length);
    }

    /**
     * @notice Batch transfer ERC20 tokens from multiple accounts
     * @param accounts Array of account addresses to transfer from
     * @param contractAddress ERC20 token contract address
     * @param amounts Array of token amounts to transfer from each account
     * @param to Recipient address
     */
    function transferERC20(
        address[] memory accounts,
        address contractAddress,
        uint256[] memory amounts,
        address to
    ) external onlyOwner nonReentrant {
        if (accounts.length != amounts.length) revert ArrayLengthMismatch();
        if (accounts.length == 0) revert EmptyArray();
        if (accounts.length > MAX_BATCH_SIZE) revert ArrayTooLarge(accounts.length, MAX_BATCH_SIZE);
        if (to == address(0)) revert InvalidAddress();
        if (contractAddress == address(0)) revert InvalidAddress();

        uint256 successCount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) {
                emit TransferFailed(accounts[i], to, "Invalid account address");
                continue;
            }

            try IAccount(accounts[i]).transferERC20(contractAddress, to, amounts[i]) {
                successCount++;
            } catch Error(string memory reason) {
                emit TransferFailed(accounts[i], to, reason);
            } catch {
                emit TransferFailed(accounts[i], to, "Unknown error");
            }
        }

        emit BatchTransferCompleted(successCount, accounts.length);
    }

    /**
     * @notice Batch transfer ERC721 NFTs from multiple accounts
     * @param accounts Array of account addresses to transfer from
     * @param contractAddress ERC721 token contract address
     * @param tokenIds Array of token IDs to transfer from each account
     * @param to Recipient address
     */
    function transferERC721(
        address[] memory accounts,
        address contractAddress,
        uint256[] memory tokenIds,
        address to
    ) external onlyOwner nonReentrant {
        if (accounts.length != tokenIds.length) revert ArrayLengthMismatch();
        if (accounts.length == 0) revert EmptyArray();
        if (accounts.length > MAX_BATCH_SIZE) revert ArrayTooLarge(accounts.length, MAX_BATCH_SIZE);
        if (to == address(0)) revert InvalidAddress();
        if (contractAddress == address(0)) revert InvalidAddress();

        uint256 successCount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) {
                emit TransferFailed(accounts[i], to, "Invalid account address");
                continue;
            }

            try IAccount(accounts[i]).transferERC721(contractAddress, tokenIds[i], to) {
                successCount++;
            } catch Error(string memory reason) {
                emit TransferFailed(accounts[i], to, reason);
            } catch {
                emit TransferFailed(accounts[i], to, "Unknown error");
            }
        }

        emit BatchTransferCompleted(successCount, accounts.length);
    }

    /**
     * @notice Batch call arbitrary contract functions from multiple accounts
     * @dev Use with extreme caution - allows arbitrary contract calls
     * @param accounts Array of account addresses to call from
     * @param contractAddress Target contract address
     * @param functionId Function selector
     * @param data ABI-encoded function parameters
     * @param amount Amount of ETH to send with each call
     */
    function callAny(
        address[] memory accounts,
        address contractAddress,
        bytes4 functionId,
        bytes memory data,
        uint256 amount
    ) external onlyOwner nonReentrant {
        if (accounts.length == 0) revert EmptyArray();
        if (accounts.length > MAX_BATCH_SIZE) revert ArrayTooLarge(accounts.length, MAX_BATCH_SIZE);
        if (contractAddress == address(0)) revert InvalidAddress();

        uint256 successCount = 0;

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == address(0)) {
                emit TransferFailed(accounts[i], contractAddress, "Invalid account address");
                continue;
            }

            try IAccount(accounts[i]).callAny(contractAddress, functionId, data, amount) {
                successCount++;
            } catch Error(string memory reason) {
                emit TransferFailed(accounts[i], contractAddress, reason);
            } catch {
                emit TransferFailed(accounts[i], contractAddress, "Unknown error");
            }
        }

        emit BatchTransferCompleted(successCount, accounts.length);
    }
}
