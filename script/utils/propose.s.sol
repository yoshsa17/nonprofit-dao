// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/interfaces/IGovernorNPO.sol";
import "./constant.sol";

contract propose is Script, Constant {
    IGovernorNPO public governor;

    function setUp() public {
        targets = [members[2]];
        values = [2 ether];
        calldatas = [abi.encodePacked("")];
        description = "# Send 2 ether to member 2";
        governor = IGovernorNPO(GovernorAddress);
    }

    function run() public {
        vm.startBroadcast();
        governor.propose(MAIN_DOMAIN_ID, targets, values, calldatas, description);
        vm.stopBroadcast();
    }
}
