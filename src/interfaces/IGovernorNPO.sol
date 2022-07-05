// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ITreasuryWallet.sol";

/**
 * @title IGovrenorNPO interface
 *       a simplified version of the IGovernor interface from the OpenZeppelin contracts.
 *       ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.0/contracts/governance/IGovernor.sol
 */
interface IGovernorNPO is ITreasuryWallet {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    enum VoteType {
        Against,
        For,
        Abstain
    }

    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    event ProposalCanceled(uint256 proposalId);

    event ProposalExecuted(uint256 proposalId);

    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    function name() external view returns (string memory);

    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external pure returns (uint256);

    function state(uint256 proposalId) external view returns (ProposalState);

    function proposalDeadline(uint256 proposalId) external view returns (uint256);

    function proposalSnapshot(uint256 proposalId) external view returns (uint256);

    function hasVoted(uint256 proposalId, address account) external view returns (bool);

    function getProposalDomain(uint256 proposalId) external view returns (bytes32);

    // function version() external view returns (string memory);
    // function quorum() external view returns (uint256);

    function propose(
        bytes32 domainId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256 proposalId);

    function castVote(
        uint256 proposalId,
        uint8,
        string memory reason
    ) external returns (uint256 balance);

    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external payable returns (uint256 proposalId);
}
