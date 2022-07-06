// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title ITreasuryWallet interface
 */
interface ITreasuryWallet {
    event EtherSent(address to, uint256 amount, string reason);
    event EtherDeposited(address from, uint256 amount);

    function getWalletBalance() external view returns (uint256);

    function getDomainAllowance(bytes32 domainId) external view returns (uint256);

    function checkDomainAllowance(bytes32 domainId, uint256[] memory values) external view returns (bool);

    function approveToDomain(bytes32 domainId, uint256 amount) external;

    function revokeDomainAllowance(bytes32 domainId) external;
}
