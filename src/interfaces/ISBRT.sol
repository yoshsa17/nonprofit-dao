// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ISBT721/ISBT721Metadata.sol";
import "./ISBT721/ISBT721.sol";
import "./IAccessControlPlus.sol";

/**
 * @title ISBRT  interface
 */
interface ISBRT is ISBT721, ISBT721Metadata, IAccessControlPlus {
    event AddedReputation(uint256 roundId, bytes32 domainId, address evaluator, address contributor, string reason);

    function getAttribute(uint256 tokenId)
        external
        view
        returns (
            address acceptedBy,
            uint256 createdAt,
            uint256 updatedAt,
            uint32 rcount,
            uint32 ecount,
            uint32 vcount,
            uint32 scount
        );

    function burnSBRT(uint256 tokenId) external;

    function incrementScount(address account) external;

    function incrementVcount(address account) external;

    function getVotes(address account) external view returns (uint256);

    function getVotesInDomain(address account, bytes32 domainId) external view returns (uint256);
}
