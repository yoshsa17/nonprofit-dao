// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./SBT721.sol";
import "../../interfaces/ISBT721/ISBT721Enumerable.sol";

/**
 * @title Soul Bound Token 721 Enumerable contract
 *
 * TODO: Need to be refactored because we force to mint only one token per user.
 *
 * @dev This contract is a non-transferable (Soulbound) version of the Openzeppelin's
 *      ERC721Enumerable contract, which inherits 'SBT721' + 'ISBT721Enumerable'.
 *      ref: https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721Enumerable
 */
abstract contract SBT721Enumerable is SBT721, ISBT721Enumerable {
    // Mapping of owner address to list of owned tokenIds
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    // Mapping of tokenId to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;
    // Mapping of tokenId to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;
    // Array of all tokenIds
    uint256[] private _allTokens;

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < SBT721.balanceOf(owner), "SBT721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < SBT721Enumerable.totalSupply(), "SBT721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenMintOrBurn(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        // Mint
        if (from == address(0)) {
            _addTokenToAllTokensAndOwnerEnumeration(to, tokenId);
        }
        // Burn
        else if (to == address(0)) {
            _removeTokenFromAllTokensAndOwnerEnumeration(from, tokenId);
        }
    }

    function _addTokenToAllTokensAndOwnerEnumeration(address to, uint256 tokenId) internal {
        // alltokens
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
        // owner
        uint256 length = SBT721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
    }

    function _removeTokenFromAllTokensAndOwnerEnumeration(address from, uint256 tokenId) internal {
        // alltokens
        uint256 lastGlobalTokenIndex = _allTokens.length - 1;
        uint256 lastGlobalTokenId = _allTokens[lastGlobalTokenIndex];
        uint256 tokenGlobalIndex = _allTokensIndex[tokenId];
        _allTokens[tokenGlobalIndex] = lastGlobalTokenId;
        _allTokensIndex[lastGlobalTokenId] = tokenGlobalIndex;
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
        // owner
        uint256 lastTokenIndex = SBT721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
}
