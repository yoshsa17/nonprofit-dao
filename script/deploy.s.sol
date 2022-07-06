// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/GovernorNPO.sol";
import "../src/SBRTManager.sol";

contract DeployContracts is Script {
    // addresses from anvil
    address[] public members = [
        0xEEa296A43DAbbA647A588cFEA80afAce851c11cb,
        0x9d4a8d88544c6B1b1c017D09391577647E6f10be,
        0x4b5A32aaFC5b0eb58dcB0831d13b71D9A851cADf
    ];
    string initialDomain = "DOMAIN_1";
    string initialAdminDomain = "DOMAIN_1_ADMIN";

    function setUp() public {}

    function run() public {
        // deploy governorNPO
        vm.startBroadcast();
        GovernorNPO governor = new GovernorNPO();
        vm.stopBroadcast();

        // deploy SBRTManager
        vm.startBroadcast();
        SBRTManager manager = new SBRTManager(address(governor), initialDomain, initialAdminDomain, members);
        vm.stopBroadcast();

        // initialize governorNPO with the manager address
        governor.init(address(manager));
    }
}
