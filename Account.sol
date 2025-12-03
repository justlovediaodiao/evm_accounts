// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./Errors.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IAccount {
    function transfer(address payable to, uint256 amount) external;
    function transferERC20(
        address contractAddress,
        address to,
        uint256 amount
    ) external;
    function transferERC721(
        address contractAddress,
        uint256 tokenId,
        address to
    ) external;
    function callAny(
        address contractAddress,
        bytes4 functionId,
        bytes memory data,
        uint256 amount
    ) external;
}

/**
 * @title Account
 * @notice Manages ETH, ERC20 tokens, and ERC721 NFTs with enhanced security
 * @dev Implements reentrancy protection and two-step ownership transfer
 */
contract Account is IAccount, Ownable2Step, ReentrancyGuard {
    // Events
    event ETHReceived(address indexed from, uint256 amount);
    event ETHTransferred(address indexed to, uint256 amount);
    event ERC20Transferred(address indexed token, address indexed to, uint256 amount);
    event ERC721Transferred(address indexed token, address indexed to, uint256 tokenId);
    event ContractCalled(address indexed target, bytes4 indexed functionId, uint256 value);

    /**
     * @dev Emitted when ETH is received
     */
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }

    /**
     * @dev Required for receiving ERC721 tokens
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /**
     * @notice Transfer ETH to a recipient
     * @param to Recipient address
     * @param amount Amount of ETH to transfer in wei
     */
    function transfer(address payable to, uint256 amount) 
        external 
        override 
        onlyOwner 
        nonReentrant 
    {
        if (to == address(0)) revert InvalidAddress();
        if (address(this).balance < amount) revert InsufficientBalance();

        // Use call instead of transfer to avoid 2300 gas limit issues
        (bool success, ) = to.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit ETHTransferred(to, amount);
    }

    /**
     * @notice Transfer ERC20 tokens to a recipient
     * @param contractAddress ERC20 token contract address
     * @param to Recipient address
     * @param amount Amount of tokens to transfer
     */
    function transferERC20(
        address contractAddress,
        address to,
        uint256 amount
    ) external override onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (contractAddress == address(0)) revert InvalidAddress();

        bool success = IERC20(contractAddress).transfer(to, amount);
        if (!success) revert ERC20TransferFailed();

        emit ERC20Transferred(contractAddress, to, amount);
    }

    /**
     * @notice Transfer ERC721 NFT to a recipient
     * @param contractAddress ERC721 token contract address
     * @param tokenId Token ID to transfer
     * @param to Recipient address
     */
    function transferERC721(
        address contractAddress,
        uint256 tokenId,
        address to
    ) external override onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        if (contractAddress == address(0)) revert InvalidAddress();

        IERC721(contractAddress).safeTransferFrom(address(this), to, tokenId);

        emit ERC721Transferred(contractAddress, to, tokenId);
    }

    /**
     * @notice Call any contract function with arbitrary data
     * @dev Use with extreme caution - allows arbitrary contract calls
     * @param contractAddress Target contract address
     * @param functionId Function selector (first 4 bytes of function signature hash)
     * @param data ABI-encoded function parameters (without selector)
     * @param amount Amount of ETH to send with the call
     */
    function callAny(
        address contractAddress,
        bytes4 functionId,
        bytes memory data,
        uint256 amount
    ) external override onlyOwner nonReentrant {
        if (contractAddress == address(0)) revert InvalidAddress();
        if (amount > address(this).balance) revert InsufficientBalance();

        (bool success, ) = contractAddress.call{value: amount}(
            abi.encodePacked(functionId, data)
        );
        if (!success) revert ContractCallFailed();

        emit ContractCalled(contractAddress, functionId, amount);
    }

    /**
     * @notice Get the ETH balance of this account
     * @return balance The current ETH balance in wei
     */
    function getBalance() external view returns (uint256 balance) {
        return address(this).balance;
    }

    /**
     * @notice Get the ERC20 token balance of this account
     * @param tokenAddress The ERC20 token contract address
     * @return balance The current token balance
     */
    function getERC20Balance(address tokenAddress) external view returns (uint256 balance) {
        if (tokenAddress == address(0)) revert InvalidAddress();
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
