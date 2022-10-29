// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/ITreasuryWallet.sol";

contract TreasuryWallet is ITreasuryWallet, Context {
    // mapping from domainId to ether amount
    mapping(bytes32 => uint256) public _domainAllowances;

    // --------------------------------------------------------------
    // Static functions
    // --------------------------------------------------------------

    function getDomainAllowance(bytes32 domainId) external view returns (uint256) {
        return domainId == bytes32(0x00) ? address(this).balance : _domainAllowances[domainId];
    }

    function checkDomainAllowance(bytes32 domainId, uint256[] memory values) external view returns (bool) {
        if (domainId == bytes32(0x00)) {
            return true;
        }
        uint256 total;
        for (uint256 i = 0; i < values.length; i++) {
            total += values[i];
        }
        return total <= _domainAllowances[domainId];
    }

    // --------------------------------------------------------------
    // External functions
    // --------------------------------------------------------------

    receive() external payable {
        if (msg.value > 0) {
            emit EtherDeposited(_msgSender(), "");
        }
    }

    function depositEth(string memory reason) external payable {
        require(msg.value > 0, "TreasuryWallet: donate amount must be greater than 0");
        emit EtherDeposited(_msgSender(), reason);
    }

    function approveToDomain(bytes32 domainId, uint256 amount) external {
        require(_msgSender() == address(this), "TreasuryWallet: only owner can approve funds");
        _domainAllowances[domainId] = amount;
        emit ApprovedToDomain(domainId, amount);
    }

    function revokeDomainAllowance(bytes32 domainId) external {
        require(_msgSender() == address(this), "TreasuryWallet: only owner can revoke funds");
        _domainAllowances[domainId] = 0;
        emit RevokedDomainAllowance(domainId);
    }
}
