// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ISBT721.sol";

/**
 * @title ISBT721Metadata interface
 *
 * @dev This interface was implemented based on the OpenZeppelin's IERC721Metadata interface.
 *      ref: https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#IERC721Metadata
 */
interface ISBT721Metadata is ISBT721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
