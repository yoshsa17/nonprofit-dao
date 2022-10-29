// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GovernorNPO.sol";
import "../src/SBRTManager.sol";

import "./utils/constant.sol";

contract DeployContracts is Script, Constant {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // deploy governorNPO
        GovernorNPO governor = new GovernorNPO();
        // deploy SBRTManager
        SBRTManager manager = new SBRTManager(address(governor), initialDomain, initialAdminDomain, members);
        // init governorNPO with SBRTManager address
        governor.init(address(manager));
        // set up initial funds
        payable(address(governor)).transfer(100 ether);
        vm.stopBroadcast();
    }
}
