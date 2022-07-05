// SPDX-License-Identifier: MI
pragma solidity ^0.8.13;

import "./ISBT721.sol";

/**
 * @title ISBT721Enumerable interface
 *
 * @dev This interface was implemented based on the OpenZeppelin's IERC721Enumerable interface.
 *      ref: https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721Enumerable
 */
interface ISBT721Enumerable is ISBT721 {
    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}
