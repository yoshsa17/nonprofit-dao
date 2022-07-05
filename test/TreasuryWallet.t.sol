// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GovernorNPO.sol";
import "../src/SBRTManager.sol";

contract TreasuryWalletTest is Test {
    // actors
    address public donor = vm.addr(123);
    // constants
    bytes32 constant DOMAIN_ID = keccak256("DOMAIN_ID");
    bytes32 constant MAIN_DOMAIN_ID = keccak256("");
    uint256[] values;
    // constants
    GovernorNPO public governor;

    function setUp() public {
        governor = new GovernorNPO();
    }

    function testReceiveEther() public {
        vm.deal(donor, 1 ether);
        vm.prank(donor);
        (bool ok, ) = payable(governor).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(governor.getWalletBalance(), 1 ether);
    }

    function testApproveFunds() public {
        vm.prank(address(governor));
        governor.approveToDomain(DOMAIN_ID, 1 ether);
        assertEq(governor.getDomainAllownance(DOMAIN_ID), 1 ether);
    }

    function testCheckDomainAllowanance() public {
        vm.startPrank(address(governor));
        values = [1, 2];
        assertFalse(governor.checkDomainAllowance(DOMAIN_ID, values));
        values = [0, 0];
        assertTrue(governor.checkDomainAllowance(DOMAIN_ID, values));
        assertTrue(governor.checkDomainAllowance(MAIN_DOMAIN_ID, values));
        vm.stopPrank();
    }
}
