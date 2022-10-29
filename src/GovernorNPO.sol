// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Timers.sol";

import "./interfaces/IGovernorNPO.sol";
import "./interfaces/ISBRTManager.sol";

import "./base/TreasuryWallet.sol";
import "./base/GovernorSettings.sol";

/**
 * @title GovernorNPO contract
 *
 * @dev A simple governor implemetation for Non-Profit DAO.
 *      This implementation is based on the OpenZeppelin Governance contract.
 *      ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/governance/Governor.sol
 */
contract GovernorNPO is IGovernorNPO, GovernorSettings, TreasuryWallet {
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    ISBRTManager public manager;
    bool private _isInitialized = false;
    string private _name = "GovernorNPO";

    struct Proposal {
        bytes32 domainId;
        Timers.BlockNumber voteStart;
        Timers.BlockNumber voteEnd;
        bool executed;
        bool canceled;
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) private _proposals;

    constructor() GovernorSettings(19636, 45818, 100) {}

    // --------------------------------------------------------------------------
    // Static functions
    // --------------------------------------------------------------------------

    function name() public view returns (string memory) {
        return _name;
    }

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        Proposal storage proposal = _proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.canceled) {
            return ProposalState.Canceled;
        }
        uint256 snapshot = proposalSnapshot(proposalId);
        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }
        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }
        uint256 deadline = proposalDeadline(proposalId);
        if (deadline >= block.number) {
            return ProposalState.Active;
        }
        if (_voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposals[proposalId].hasVoted[account];
    }

    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        Proposal storage proposal = _proposals[proposalId];
        return (proposal.againstVotes, proposal.forVotes, proposal.abstainVotes);
    }

    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    function getProposalDomain(uint256 proposalId) public view virtual override returns (bytes32) {
        return _proposals[proposalId].domainId;
    }

    // ---------------------------------------------------------------------
    // External functions
    // ---------------------------------------------------------------------

    function propose(
        bytes32 domainId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        address proposer = _msgSender();
        require(_getVotes(proposer, domainId) >= proposalThreshold(), "GovernorNPO: votes below proposalthreshold");
        require(targets.length == values.length, "GovernorNPO: invalid proposal length");
        require(targets.length == calldatas.length, "GovernorNPO: invalid proposal length");
        require(this.checkDomainAllowance(domainId, values), "GovernorNPO: insufficient domain allowance");
        // require(targets.length > 0, "GovernorNPO: empty proposal");
        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));
        Proposal storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "GovernorNPO: proposal already exists");
        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();
        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);
        proposal.domainId = domainId;
        emit ProposalCreated(
            proposalId,
            domainId,
            proposer,
            targets,
            values,
            calldatas,
            snapshot,
            deadline,
            description
        );
        manager.incrementScount(proposer); // increment submission proposal count for proposer
        return proposalId;
    }

    function castVote(
        uint256 proposalId,
        uint8 support,
        string memory reason
    ) public virtual override returns (uint256) {
        require(state(proposalId) == ProposalState.Active, "GovernorNPO: vote not currently active");
        address voter = _msgSender();
        Proposal storage proposal = _proposals[proposalId];
        require(!proposal.hasVoted[voter], "GovernorNPO: vote already cast");
        uint256 weight;
        if (proposal.domainId == bytes32(0x00)) {
            weight = manager.getVotes(voter);
        } else {
            require(manager.hasRole(proposal.domainId, voter), "GovernorNPO: voter is not a member of the domain");
            weight = manager.getVotesInDomain(voter, proposal.domainId);
        }
        proposal.hasVoted[voter] = true;
        if (support == uint8(VoteType.Against)) {
            proposal.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposal.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposal.abstainVotes += weight;
        } else {
            revert("GovernorNPO: invalid value for enum VoteType");
        }

        emit VoteCast(voter, proposalId, support, weight, reason);
        manager.incrementVcount(voter); // increment vote count for voter
        return weight;
    }

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);
        require(status == ProposalState.Succeeded, "GovernorNPO: proposal not successful");
        _proposals[proposalId].executed = true;
        emit ProposalExecuted(proposalId);

        string memory errorMessage = "GovernorNPO: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }

        return proposalId;
    }

    // --------------------------------------------------------------------------
    // Internal functions
    // --------------------------------------------------------------------------

    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool) {
        Proposal storage proposalvote = _proposals[proposalId];
        return proposalvote.forVotes > proposalvote.againstVotes;
    }

    function _getVotes(address account, bytes32 domainId) internal view virtual returns (uint256) {
        if (domainId == bytes32(0x00)) {
            return manager.getVotes(account);
        } else {
            return manager.getVotesInDomain(account, domainId);
        }
    }

    function init(address managerAddress) external {
        require(_isInitialized == false, "This function was already called");
        manager = ISBRTManager(managerAddress);
        _isInitialized = true;
    }
     
    // function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
    //     Proposal storage proposalvote = _proposals[proposalId];
    //     return proposalSnapshot(proposalId)) <= proposalvote.forVotes + proposalvote.abstainVotes;
    //     // return quorum(proposalSnapshot(proposalId)) <= proposalvote.forVotes + proposalvote.abstainVotes;
}
