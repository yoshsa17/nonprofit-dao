// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Evaluation Settings contract
 *
 * @dev This contract manages evaluation settings
 */
contract EvaluationSettings {
    // Evaluation limits per an evaluation round
    uint8 private _maxEvaluationLimit;
    // Evaluation period in block number
    uint64 private _evaluationPeriod;

    event SetMaxEvaluationLimit(uint8 oldMaxEvaluation, uint8 newMaxEvaluation);
    event SetEvaluationPeriod(uint64 oldEvaluationPeriod, uint64 newEvaluationPeriod);

    constructor(uint8 initialMaxEvaluationLimit_, uint64 initialEvaluationPeriod_) {
        _maxEvaluationLimit = initialMaxEvaluationLimit_;
        _evaluationPeriod = initialEvaluationPeriod_;
    }

    function maxEvaluationLimit() public view returns (uint8) {
        return _maxEvaluationLimit;
    }

    function evaluationPeriod() public view returns (uint64) {
        return _evaluationPeriod;
    }

    function _setEvaluationLimit(uint8 newMaxEvaluationLimit_) internal virtual {
        require(newMaxEvaluationLimit_ > 0);
        uint8 oldMaxEvaluation = _maxEvaluationLimit;
        _maxEvaluationLimit = newMaxEvaluationLimit_;
        emit SetMaxEvaluationLimit(oldMaxEvaluation, newMaxEvaluationLimit_);
    }

    function _setEvaluationPeriod(uint64 newEvaluationPeriod_) internal virtual {
        require(newEvaluationPeriod_ > 0);
        uint64 oldEvaluationPeriod = _evaluationPeriod;
        _evaluationPeriod = newEvaluationPeriod_;
        emit SetEvaluationPeriod(oldEvaluationPeriod, newEvaluationPeriod_);
    }
}
