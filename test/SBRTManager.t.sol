// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SBRTManager.sol";

contract SBRTTest is Test {
    // // actors
    address[] public role1Members = [address(1), address(2)];
    address[] public role2Members = [address(5), address(6)];
    address[] public role1Address1 = [address(1)];

    // constants
    string public NAME = "Soulbound Reputation Token";
    string public SYMBOL = "SBRT";
    bytes32 public GOVERNOR_ROLE_ID = keccak256("GOVERNOR");
    bytes32 public EVALUATOION_MANAGER_ROLE_ID = keccak256("EVALUATION_MANAGER");
    string public ROLE_1 = "ROLE_1";
    string public ROLE_2 = "ROLE_2";
    string public ROLE_1_ADMIN = "ROLE_1_ADMIN";
    string public ROLE_2_ADMIN = "ROLE_2_ADMIN";
    bytes32 public ROLE_1_ID = keccak256(abi.encodePacked(ROLE_1));
    bytes32 public ROLE_2_ID = keccak256(abi.encodePacked(ROLE_2));
    bytes32 public ROLE_1_ADMIN_ID = keccak256(abi.encodePacked(ROLE_1_ADMIN));
    bytes32 public ROLE_2_ADMIN_ID = keccak256(abi.encodePacked(ROLE_2_ADMIN));
    uint256 public evaluationPeriod = 465323; // 1 week
    address[] public contributors1 = [address(1), address(2)];
    address[] public contributors2 = [address(3), address(4)];
    string[] public reasons = ["reason1", "reason2"];
    string[] public reasons2 = ["reason3"];

    // contracts
    address public governor;
    SBRTManager public manager;

    function setUp() public {
        governor = address(0x777);
        vm.prank(address(1));
        manager = new SBRTManager(address(0x777), ROLE_1, ROLE_1_ADMIN, role1Members);
    }

    // {AccessControlPlus.sol}
    function testInitRoles() public {
        assertEq(manager.hasRole(GOVERNOR_ROLE_ID, address(0x777)), true);
        assertEq(manager.hasRole(ROLE_1_ID, address(1)), true);
        assertEq(manager.hasRole(ROLE_1_ADMIN_ID, address(1)), true);
        assertEq(manager.getRoleAdmin(ROLE_1_ID), ROLE_1_ADMIN_ID);
        assertEq(manager.getMemberRoleCount(address(1)), 2);
        assertEq(manager.getRoleName(ROLE_1_ID), ROLE_1);
        assertEq(manager.getRoleName(ROLE_1_ADMIN_ID), ROLE_1_ADMIN);
        assertEq(manager.roleExists(ROLE_1_ID), true);
        assertEq(manager.roleExists(ROLE_1_ADMIN_ID), true);
    }

    // {SBRT.sol}
    function testInitSBT721() public {
        // SBT721 metadata
        assertEq(manager.name(), NAME);
        assertEq(manager.symbol(), SYMBOL);
        // SBT72 enumerable
        assertEq(manager.totalSupply(), role1Members.length);
        uint256 tokenId = manager.tokenOfOwnerByIndex(address(1), 0);
        // SBT721
        assertEq(manager.ownerOf(tokenId), address(1));
        assertEq(manager.balanceOf(address(1)), 1);
        assertEq(manager.balanceOf(address(2)), 1);
        // SBRT
        manager.tokenURI(2);
    }

    function testInitAttribute() public {
        // Attribute
        (address acceptedBy, uint256 createdAt, uint256 updatedAt, uint256 r, uint256 e, uint256 v, uint256 s) = manager
            .getAttribute(manager.tokenOfOwnerByIndex(address(1), 0));
        assertEq(acceptedBy, address(1));
        assertEq(createdAt, updatedAt);
        assertEq(r, 1);
        assertEq(e, 0);
        assertEq(v, 0);
        assertEq(s, 0);
    }

    function testSetEvaluationRound() public {
        uint64 startBlock = uint64(block.number) + 5;
        vm.prank(governor);
        manager.setEvaluationRound(ROLE_1_ID, startBlock);
        assertEq(manager.getRoundDomainId(1), ROLE_1_ID);
        assertEq(manager.stateOf(1), "PENDING");
        vm.roll(startBlock); // set blocknumber to startBlock
        assertEq(manager.stateOf(1), "IN_PROGRESS");
        vm.roll(block.number + evaluationPeriod); // set blocknumber to startBlock + evaluationPeriod
        assertEq(manager.stateOf(1), "ENDED");
    }

    // when add reputation to a new user, it should mint a new token
    function testAddReputationMint() public {
        uint64 startBlock = uint64(block.number) + 5;
        vm.prank(governor);
        manager.setEvaluationRound(ROLE_1_ID, startBlock);
        vm.roll(startBlock); // set blocknumber to 7

        vm.prank(address(1));
        manager.evaluate(1, contributors2, reasons);
        assertEq(manager.balanceOf(address(3)), 1);
        uint256 tokenId = manager.tokenOfOwnerByIndex(address(3), 0);
        (, , , uint256 rcount, , , ) = manager.getAttribute(tokenId);
        assertEq(rcount, 1);
    }

    function testAddNewRole() public {
        vm.prank(governor);
        manager.addNewRole("ROLE_2", "ROLE_2_ADMIN", role2Members);
        assertEq(manager.hasRole(ROLE_2_ID, address(5)), true);
        assertEq(manager.hasRole(ROLE_2_ID, address(6)), true);
        assertEq(manager.getMemberRoleCount(address(5)), 2);
        assertEq(manager.getMemberRoleCount(address(6)), 2);
    }

    // when adding reputation to a user who already has a token, but not in the same domain,
    // it should grant role and add a new reputation
    function testAddReputationInNewDomain() public {
        // add new role
        vm.prank(governor);
        manager.addNewRole("ROLE_2", "ROLE_2_ADMIN", role2Members);
        // set evaluation round
        uint64 startBlock = uint64(block.number) + 5;
        vm.prank(governor);
        manager.setEvaluationRound(ROLE_2_ID, startBlock);
        vm.roll(startBlock); // set blocknumber to startBlock

        vm.prank(address(5));
        manager.evaluate(1, role1Members, reasons);
        assertEq(manager.hasRole(ROLE_2_ID, address(1)), true);
        assertEq(manager.getMemberRoleCount(address(1)), 3);
        uint256 tokenId = manager.tokenOfOwnerByIndex(address(1), 0);
        (, , , uint256 rcount, , , ) = manager.getAttribute(tokenId);
        assertEq(rcount, 2);
    }

    // when add a reputation to a user who already has a manager, and in the same domain, it should
    // add a new repingutation.
    function testAddReputationInSameDomain() public {
        uint64 startBlock = uint64(block.number) + 5;
        vm.prank(governor);
        manager.setEvaluationRound(ROLE_1_ID, startBlock);
        vm.roll(startBlock); // set blocknumber to startBlock

        vm.prank(address(2));
        manager.evaluate(1, role1Address1, reasons2);
        uint256 tokenId = manager.tokenOfOwnerByIndex(address(1), 0);
        (, , , uint256 rcount, , , ) = manager.getAttribute(tokenId);
        assertEq(rcount, 2);
        assertEq(manager.getMemberRoleCount(address(1)), 2);
    }

    function testGetVotes() public {
        assertEq(manager.getVotes(address(1)), 100);
        assertEq(manager.getVotesInDomain(address(1), ROLE_1_ID), 100);
    }
}
