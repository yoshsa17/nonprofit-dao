// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ISBT721 interface
 *
 * @dev This interface was implementaed based on the OpenZeppelin's IERC721 interface.
 *      All functions/events related to the 'transfer' function have been removed.
 *      ref: https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721
 */
interface ISBT721 {
    event Minted(address indexed src, address indexed to, uint256 indexed id);

    event Burned(address indexed owner, uint256 indexed id);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}
