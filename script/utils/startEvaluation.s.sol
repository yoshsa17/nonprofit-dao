// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/interfaces/IGovernorNPO.sol";
import "./constant.sol";

contract startEvaluation is Script, Constant {
    IGovernorNPO public governor;

    function setUp() public {
        targets = [SBRTManagerAddress];
        values = [0 ether];
        calldatas = [abi.encodePacked("")];
        description = "# Start Evaluation Round in DOMAIN_1";
        governor = IGovernorNPO(GovernorAddress);
    }

    function run() public {
        vm.startBroadcast();
        governor.propose(MAIN_DOMAIN_ID, targets, values, calldatas, description);
        vm.stopBroadcast();
    }
}
