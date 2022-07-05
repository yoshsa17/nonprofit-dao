// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/ISBRT.sol";

import "./SBT721/SBT721Enumerable.sol";
import "./DataURIGen.sol";
import "./AccessControlPlus.sol";

/**
 * @title Soul Bound Reputation Token contract
 *
 * @dev A SBRT (Soul Bound Reputation Token) is a non-transferable(Soulbound) NFT representing a reputation.
 *      This contract manages SRBTs and its attributes + Role based access control.
 */
contract SBRT is ISBRT, SBT721Enumerable, AccessControlPlus, DataURIGen {
    uint256 public constant REPUTATION_VALID_PERIOD = 60 * 60 * 24 * 7 * 4; // 1 month
    uint256 public constant REPUTAIION_INITIAL_WEIGHT = 100;
    uint256 public constant EVALUATION_INITIAL_WEIGHT = 10;
    uint256 public constant PROPOSAL_INIRIAL_WEIGHT = 10;
    uint256 public constant VOTING_INITIAL_WEIGHT = 10;

    enum MemberStatus {
        INACTIVE,
        ACTIVE
    }

    struct Attribute {
        address acceptedBy;
        uint256 createdAt;
        uint256 updatedAt;
        uint32 rcount; // reputation count
        uint32 ecount; // evaluation count
        uint32 vcount; // voting count
        uint32 scount; // proposal submission count
        ReputationDetail[] reputations;
    }

    struct ReputationDetail {
        bytes32 domainId;
        address evaluator;
        uint256 createdAt;
    }

    // Mapping of tokenId to its attribute
    mapping(uint256 => Attribute) private _attributes;

    constructor(
        address governor_,
        string memory initialRoleName_,
        string memory initialAdminRoleName_,
        address[] memory initialMembers_
    ) SBT721("Soulbound Reputation Token", "SBRT") {
        _grantRole(GOVERNOR, governor_);
        _addNewRole(initialRoleName_, initialAdminRoleName_, initialMembers_);
    }

    // -------------------------------------------------------------------------
    // Static functions
    // -------------------------------------------------------------------------

    /**
     * @dev Overrides the SBT721 implementation to return the dataURI (SVG data).
     */
    function tokenURI(uint256 tokenId) external view override(SBT721, ISBT721Metadata) returns (string memory) {
        _exists(tokenId);
        Attribute storage a = _attributes[tokenId];
        address owner = ownerOf(tokenId);
        string[] memory roles = getGrantedRoles(owner);
        string memory status = a.updatedAt + REPUTATION_VALID_PERIOD > block.timestamp ? "ACTIVE" : "INACTIVE";

        return
            getDataURI(
                tokenId,
                ownerOf(tokenId),
                roles,
                status,
                block.timestamp,
                a.acceptedBy,
                a.rcount,
                a.ecount,
                a.vcount,
                a.scount
            );
    }

    /**
     * @dev Returns an Attribute of a token.
     */
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
        )
    {
        return (
            _attributes[tokenId].acceptedBy,
            _attributes[tokenId].createdAt,
            _attributes[tokenId].updatedAt,
            _attributes[tokenId].rcount,
            _attributes[tokenId].ecount,
            _attributes[tokenId].vcount,
            _attributes[tokenId].scount
        );
    }

    /**
     * @dev Returns voting power of the given account in the domain.
     * TODO:: refactor to get socres only from the domain
     */
    function getVotesInDomain(address account, bytes32 domainId) external view returns (uint256) {
        if (!hasRole(domainId, account) || this.getMemberStatus(account) == MemberStatus.INACTIVE) {
            return 0;
        }
        uint256 tokenId = tokenOfOwnerByIndex(account, 0);
        uint256 eScore = _attributes[tokenId].ecount * EVALUATION_INITIAL_WEIGHT;
        uint256 vScore = _attributes[tokenId].vcount * VOTING_INITIAL_WEIGHT;
        uint256 sScore = _attributes[tokenId].scount * PROPOSAL_INIRIAL_WEIGHT;
        uint256 rScore = _calcReputationScoreInDaomin(tokenId, domainId);
        return rScore + eScore + vScore + sScore;
    }

    function getVotes(address account) external view returns (uint256) {
        if (getMemberRoleCount(account) == 0 || this.getMemberStatus(account) == MemberStatus.INACTIVE) {
            return 0;
        }
        uint256 tokenId = tokenOfOwnerByIndex(account, 0);
        uint256 eScore = _attributes[tokenId].ecount * EVALUATION_INITIAL_WEIGHT;
        uint256 vScore = _attributes[tokenId].vcount * VOTING_INITIAL_WEIGHT;
        uint256 sScore = _attributes[tokenId].scount * PROPOSAL_INIRIAL_WEIGHT;
        uint256 rScore = _calcReputationScore(tokenId);
        return rScore + eScore + vScore + sScore;
    }

    function getMemberStatus(address member) external view returns (MemberStatus) {
        require(getMemberRoleCount(member) > 0, "account is not a member of any role");
        uint256 tokenId = tokenOfOwnerByIndex(member, 0);
        Attribute storage a = _attributes[tokenId];
        return a.updatedAt + REPUTATION_VALID_PERIOD > block.timestamp ? MemberStatus.ACTIVE : MemberStatus.INACTIVE;
    }

    // -------------------------------------------------------------------------
    // External functions
    // -------------------------------------------------------------------------

    /**
     * @dev Burns a SBRT by the given tokenId and delete the attribute tied with the SBRT.
     *      This function must be called by the Govrenor contact
     */
    function burnSBRT(uint256 tokenId) external onlyRole(GOVERNOR) {
        // Deletes all roles of the address who owns the SBRT
        address owner = ownerOf(tokenId);
        _revokeAllRoles(owner);
        // Burns the SBRT
        _burn(tokenId);
        // Deletes the attribute tied with the SBRT
        _deleteAttribute(tokenId);
        emit Burned(owner, tokenId);
    }

    /**
     * @dev increments the proposal submission count of the given SBRT and updates its timestamp
     */
    function incrementScount(address account) external onlyRole(GOVERNOR) {
        uint256 tokenId = tokenOfOwnerByIndex(account, 0);
        unchecked {
            _attributes[tokenId].scount++;
        }
        _attributes[tokenId].updatedAt = block.timestamp;
    }

    /**
     * @dev increments the voting count of the given SBRT and updates its timestamp
     */
    function incrementVcount(address account) external onlyRole(GOVERNOR) {
        uint256 tokenId = tokenOfOwnerByIndex(account, 0);
        unchecked {
            _attributes[tokenId].vcount++;
        }
        _attributes[tokenId].updatedAt = block.timestamp;
    }

    // -------------------------------------------------------------------------
    // Internal functions
    // -------------------------------------------------------------------------

    /**
     * @dev Adds a new reputation to the given SBRT.
     * Note: the 'reason' pram is not stored in the chain storage, but in 'AddedReputation' event.
     */
    function _addReputation(
        address from,
        address to,
        bytes32 domainId,
        uint256 roundId,
        string memory reason
    ) internal {
        // if the 'to' address does not have a SBRT yet, mint a new one and add a reputation
        if (balanceOf(to) == 0) {
            // check if the 'from' address is a member of admin role and grant role to 'to' address
            require(hasRole(getRoleAdmin(domainId), from), "SBRT: from address is not a member of the Admin role");
            _mintSBRT(from, to, domainId, roundId, reason);
        }
        // if the 'to' already has a SBRT but has not acccepted yet in the given domain,
        // then grant a new role and add a reputation to the SBRT
        else if (!hasRole(domainId, to)) {
            // Only the admin of the domain can grant its role.
            require(hasRole(getRoleAdmin(domainId), from), "SBRT: from address is not a member of the admin role");
            _grantRole(domainId, to);
            _addReputationToSBRT(from, to, domainId, roundId, reason);
        }
        // if the 'to' already has a SBRT and has accepted the given domain, then just add
        // a new reputation to the SBRT
        else if (hasRole(domainId, to)) {
            // Only the member of the domain can add a reputation.
            require(hasRole(domainId, from), "SBRT: from address is not a member of the role");
            _addReputationToSBRT(from, to, domainId, roundId, reason);
        }
    }

    /**
     * @dev Mints a new SBRT to the given contributor and append an initial Reputation to it.
     *      The 'from' address must be the admin of the domain.
     */
    function _mintSBRT(
        address from,
        address to,
        bytes32 domainId,
        uint256 roundId,
        string memory reason
    ) internal {
        // grant role to 'to' address
        _grantRole(domainId, to);
        // mint a new SBRT and append an initial reputation to
        uint256 tokenId = totalSupply() + 1;

        _mint(to, tokenId);
        _initAttribute(tokenId, from, to, domainId, roundId, reason);
    }

    /**
     * @dev Initializes the attribute of the given SBRT.
     *     This function must be called after a SBRT is newly minted.
     */
    function _initAttribute(
        uint256 tokenId,
        address from,
        address to,
        bytes32 domainId,
        uint256 roundId,
        string memory reason
    ) internal {
        // compose a new reputation detail
        ReputationDetail memory newReputation = ReputationDetail(domainId, from, block.timestamp);
        // init the attributes and append the reputation detail to it
        Attribute storage a = _attributes[tokenId];
        a.acceptedBy = from;
        a.createdAt = block.timestamp;
        a.updatedAt = block.timestamp;
        a.rcount = 1;
        a.reputations.push(newReputation);
        emit AddedReputation(roundId, domainId, from, to, reason);
    }

    /**
     * @dev Adds a new reputation
     */
    function _addReputationToSBRT(
        address from,
        address to,
        bytes32 domainId,
        uint256 roundId,
        string memory reason
    ) internal {
        // TODO: fix this when the SBR721Enumerable is redacted
        uint256 tokenId = tokenOfOwnerByIndex(to, 0);
        ReputationDetail memory newReputation = ReputationDetail(domainId, from, block.timestamp);
        Attribute storage a = _attributes[tokenId];
        a.reputations.push(newReputation);
        a.updatedAt = block.timestamp;
        unchecked {
            a.rcount++;
        }

        emit AddedReputation(roundId, domainId, from, to, reason);
    }

    /**
     * @dev Deletes the attributes of the given SBRT.
     *      This function must be called after a SBRT is burned.
     */
    function _deleteAttribute(uint256 tokenId) internal {
        delete _attributes[tokenId];
    }

    /**
     * @dev Overrides the _addNewRole function {AccessControlPlus}
     */
    function _addNewRole(
        string memory roleName,
        string memory adminRoleName,
        address[] memory members
    ) internal override {
        bytes32 roleId = keccak256(abi.encodePacked(roleName));
        bytes32 adminRoleId = keccak256(abi.encodePacked(adminRoleName));
        _setRoleName(roleId, roleName);
        _setRoleName(adminRoleId, adminRoleName);
        _setRoleAdmin(roleId, adminRoleId);
        for (uint256 i = 0; i < members.length; i++) {
            // add reputation in the new role and grant role to each member
            if (balanceOf(members[i]) == 0) {
                _mintSBRT(_msgSender(), members[i], roleId, 0, "Initial Memeber");
            } else {
                _grantRole(roleId, members[i]);
                _addReputationToSBRT(_msgSender(), members[i], roleId, 0, "Initial Member");
            }
            // grant admin role to each member
            _grantRole(adminRoleId, members[i]);
        }
    }

    /**
     * @dev increments the evaluation count of the given SBRT and updates its timestamp
     */
    function _incrementEcount(uint256 tokenId) internal {
        unchecked {
            _attributes[tokenId].ecount++;
        }
        _attributes[tokenId].updatedAt = block.timestamp;
    }

    /**
     * @dev Calculates the reputation score of the given SBRT.
     */
    function _calcReputationScore(uint256 tokenId) internal view returns (uint256) {
        uint256 validIndex = _findValidReputationIndex(tokenId);
        ReputationDetail[] storage array = _attributes[tokenId].reputations;
        uint256 total = (array.length - validIndex) * REPUTAIION_INITIAL_WEIGHT;
        return total;
    }

    /**
     * @dev Calculates the reputation score in the given domain.
     */
    function _calcReputationScoreInDaomin(uint256 tokenId, bytes32 domainId) internal view returns (uint256) {
        uint256 validIndex = _findValidReputationIndex(tokenId);
        ReputationDetail[] storage array = _attributes[tokenId].reputations;
        uint256 total = 0;
        for (uint256 i = validIndex; i < array.length; i++) {
            if (array[i].domainId == domainId) {
                total += REPUTAIION_INITIAL_WEIGHT;
            }
        }
        return total;
    }

    /**
     * @dev Returns the first index that contains a createdAt greater or equal to block.timestamp
     *      ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/utils/Arrays.sol
     */
    function _findValidReputationIndex(uint256 tokenId) internal view returns (uint256) {
        ReputationDetail[] storage array = _attributes[tokenId].reputations;
        uint256 current = block.timestamp;

        if (array.length == 0) {
            return 0;
        }
        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (array[mid].createdAt > current) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].createdAt == current) {
            return low - 1;
        } else {
            return low;
        }
    }
}
