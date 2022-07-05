// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";

import "../interfaces/ITreasuryWallet.sol";

contract TreasuryWallet is ITreasuryWallet, Context {
    // mapping from domainId to ether amount
    mapping(bytes32 => uint256) public _domainAllownances;

    // --------------------------------------------------------------
    // Static functions
    // --------------------------------------------------------------

    function getWalletBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getDomainAllownance(bytes32 domainId) external view returns (uint256) {
        return _domainAllownances[domainId];
    }

    function checkDomainAllowance(bytes32 domainId, uint256[] memory values) external view returns (bool) {
        if (domainId == bytes32(0x00)) {
            return true;
        }
        uint256 total;
        for (uint256 i = 0; i < values.length; i++) {
            total += values[i];
        }
        return total <= _domainAllownances[domainId];
    }

    // --------------------------------------------------------------
    // External functions
    // --------------------------------------------------------------

    receive() external payable {
        if (msg.value > 0) {
            emit EtherDeposited(_msgSender(), msg.value);
        }
    }

    function approveToDomain(bytes32 domainId, uint256 amount) external {
        require(_msgSender() == address(this), "TreasuryWallet: only owner can approve funds");
        _domainAllownances[domainId] = amount;
    }

    function revokeDomainAllownance(bytes32 domainId) external {
        require(_msgSender() == address(this), "TreasuryWallet: only owner can revoke funds");
        _domainAllownances[domainId] = 0;
    }
}
