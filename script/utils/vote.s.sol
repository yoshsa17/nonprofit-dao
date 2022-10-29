// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../../src/interfaces/IGovernorNPO.sol";
import "./constant.sol";

contract vote is Script, Constant {
    IGovernorNPO public governor;
    uint256 public proposalId = 85725626321775914367884930142511350824347662352248820873732851121667903538749;
    uint8 public support = 1; // For vote
    string public reason = "Cast vote for proposal #1";

    function setUp() public {
        governor = IGovernorNPO(GovernorAddress);
    }

    function run() public {
        vm.startBroadcast();
        governor.castVote(proposalId, support, reason);
        vm.stopBroadcast();
    }
}
