// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ISBRT.sol";

/**
 * @title ISBRT Manager contract
 */
interface ISBRTManager is ISBRT {
    event SetEvaluationRound(uint256 roundId, uint64 startBlock, uint64 endBlock);

    function isEvaluator(bytes32 domainId, address account) external view returns (bool);

    function getRoundDomainId(uint256 roundId) external view returns (bytes32);

    function evaluate(
        uint256 roundId,
        address[] calldata contributors,
        string[] calldata reasons
    ) external returns (bool);

    function setEvaluationRound(bytes32 domainId, uint64 startBlock) external returns (bool);
}
