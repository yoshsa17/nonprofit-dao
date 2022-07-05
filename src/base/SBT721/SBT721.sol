// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";

import "../../interfaces/ISBT721/ISBT721.sol";
import "../../interfaces/ISBT721/ISBT721Metadata.sol";

/**
 * @title Soul Bound Tokne 721 contract
 *
 * @dev This contract is a non-transferable (Soulbound) version of the Openzeppelin's
 *      ERC721 contract, which inherits 'ISBT721' + 'ISBT721Metadata'.
 *      ref: https://docs.openzeppelin.com/contracts/4.x/api/token/erc721#ERC721
 *
 *      NOTE: This contract is not compatible with the 'ERC721'.
 */
contract SBT721 is ISBT721, ISBT721Metadata {
    using Strings for uint256;

    string private _name;
    string private _symbol;
    string private _tokenBaseURI;
    // Mapping of 'tokenId' to owner address
    mapping(uint256 => address) private _owners;
    // Mapping of owner address to balance of tokens
    mapping(address => uint256) private _balances;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // -------------------------------------------------------------------------
    // Static functions
    // -------------------------------------------------------------------------

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "SBT: zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "SBT: zero address");
        return owner;
    }

    // -------------------------------------------------------------------------
    // Internal functions
    // -------------------------------------------------------------------------

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "SBT: invalid token id");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "SBT:  zero address");
        require(!_exists(tokenId), "SBT: token already minted");
        _beforeTokenMintOrBurn(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Minted(address(0), to, tokenId);
        _afterTokenMintOrBurn(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = SBT721.ownerOf(tokenId);
        _beforeTokenMintOrBurn(owner, address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Burned(owner, tokenId);
        _afterTokenMintOrBurn(owner, address(0), tokenId);
    }

    function _beforeTokenMintOrBurn(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenMintOrBurn(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
