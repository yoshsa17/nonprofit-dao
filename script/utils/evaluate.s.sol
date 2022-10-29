// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/interfaces/ISBRTManager.sol";
import "./constant.sol";

// This contract is used to test the GovernorNPO contract.
contract evaluate is Script, Constant {
    ISBRTManager public manager;
    uint256 public roundId;
    address[] public contributors;
    string[] public reasons;

    function setUp() public {
        roundId = 1;
        contributors = [members[1]];
        reasons = ["Nice work!"];
        manager = ISBRTManager(SBRTManagerAddress);
    }

    function run() public {
        vm.startBroadcast();
        manager.evaluate(roundId, contributors, reasons);
        vm.stopBroadcast();
    }
}
