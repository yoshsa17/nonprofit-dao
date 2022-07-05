// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/ISBRTManager.sol";
import "./base//AccessControlPlus.sol";
import "./base/EvaluationSettings.sol";
import "./base/SBRT.sol";

/**
 * @title SBRT Manager contract
 *        This contract is a wrapper contract of the SRBT contract to mint SBRTs and add reputations to SBRTs
 *        based on peer evaluation.
 */
contract SBRTManager is ISBRTManager, SBRT, EvaluationSettings {
    using Counters for Counters.Counter;
    using Timers for Timers.BlockNumber;

    enum State {
        PENDING,
        IN_PROGRESS,
        ENDED
    }

    struct EvaluationRound {
        bytes32 domainId;
        Timers.BlockNumber startBlock;
        Timers.BlockNumber endBlock;
        mapping(address => bool) hasEvaluated;
    }
    // Mapping of 'roundId' to 'round'
    mapping(uint256 => EvaluationRound) private _evaluationRounds;
    // Evaluation round counter
    Counters.Counter private _evaluationRoundCount;

    constructor(
        address governor_,
        string memory initialRoleName_,
        string memory initialAdminRoleName_,
        address[] memory initialMembers_
    ) SBRT(governor_, initialRoleName_, initialAdminRoleName_, initialMembers_) EvaluationSettings(3, 46523) {}

    // -------------------------------------------------------------------------
    // Static functions
    // -------------------------------------------------------------------------

    /**
     * @dev Returns true if the given address is a member of the given role.
     */
    function isEvaluator(bytes32 domainId, address account) external view returns (bool) {
        return hasRole(domainId, account);
    }

    function getRoundDomainId(uint256 roundId) external view returns (bytes32) {
        require(roundId <= _evaluationRoundCount.current(), "SBRTManager:: RoundId id is out of range");
        return _evaluationRounds[roundId].domainId;
    }

    function stateOf(uint256 roundId) external view returns (string memory) {
        if (_stateOf(roundId) == State.PENDING) {
            return "PENDING";
        } else if (_stateOf(roundId) == State.IN_PROGRESS) {
            return "IN_PROGRESS";
        } else if (_stateOf(roundId) == State.ENDED) {
            return "ENDED";
        } else {
            return "UNKNOWN";
        }
    }

    function _stateOf(uint256 roundId) internal view returns (State) {
        require(roundId <= _evaluationRoundCount.current(), "SBRTManager:: RoundId id is out of range");
        if (_evaluationRounds[roundId].startBlock.isPending()) {
            return State.PENDING;
        } else if (_evaluationRounds[roundId].endBlock.isExpired()) {
            return State.ENDED;
        } else {
            return State.IN_PROGRESS;
        }
    }

    // -------------------------------------------------------------------------
    // External functions
    // -------------------------------------------------------------------------

    /**
     * @dev Only domain members can call this function.
     */
    function evaluate(
        uint256 roundId,
        address[] calldata contributors,
        string[] calldata reasons
    ) external returns (bool) {
        // Check if round is currently in progress
        require(_stateOf(roundId) == State.IN_PROGRESS, "SBRTManager:: The round is not in progress");
        // Check if the caller is an evaluator(member of the domain)
        require(
            hasRole(this.getRoundDomainId(roundId), _msgSender()),
            "SBRTManager:: Only domain members can evaluate"
        );
        // Check if the caller has already evaluated
        require(
            _evaluationRounds[roundId].hasEvaluated[_msgSender()] == false,
            "SBRTManager:: You have already evaluated this round"
        );
        // Check if the number of contributors is correct
        require(
            contributors.length <= maxEvaluationLimit() && contributors.length == reasons.length,
            "SBRTManager:: The number of contributors is not correct"
        );
        for (uint256 i = 0; i < contributors.length; i++) {
            _addReputation(_msgSender(), contributors[i], this.getRoundDomainId(roundId), roundId, reasons[i]);
        }
        // Set isEvaluated to true
        _evaluationRounds[roundId].hasEvaluated[_msgSender()] = true;
        // Increase the number of ecount
        _incrementEcount(tokenOfOwnerByIndex(_msgSender(), 0));
        return true;
    }

    function setEvaluationRound(bytes32 domainId, uint64 startBlock) external onlyRole(GOVERNOR) returns (bool) {
        require(roleExists(domainId), "SBRTManager: Domain does not exist");

        // Registers a new evaluation round
        _evaluationRoundCount.increment();
        uint256 roundId = _evaluationRoundCount.current();
        uint64 endBlock = startBlock + evaluationPeriod();
        EvaluationRound storage e = _evaluationRounds[roundId];
        e.startBlock.setDeadline(startBlock);
        e.endBlock.setDeadline(endBlock);
        e.domainId = domainId;
        emit SetEvaluationRound(_evaluationRoundCount.current(), startBlock, endBlock);
        return true;
    }

    function setEvaluationLimit(uint8 newMaxEvaluationLimit) external onlyRole(GOVERNOR) {
        _setEvaluationLimit(newMaxEvaluationLimit);
    }

    function setEvaluationPeriod(uint64 evaluationPeriod) external onlyRole(GOVERNOR) {
        _setEvaluationPeriod(evaluationPeriod);
    }
}
