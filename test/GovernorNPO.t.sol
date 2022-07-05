// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/GovernorNPO.sol";
import "../src/SBRTManager.sol";

import "./mocks/MockTarget.sol";

uint256 constant VOTING_DELAY = 19636; // 3 days
uint256 constant VOTING_PERIOD = 45818; // 1 week
uint256 constant QUORUM_FRACTION = 60; // 60%
uint256 constant PROPOSAL_THRESHOLD = 100; // 1 reputation
bytes32 constant DOMAIN_1_ID = keccak256("DOMAIN_1");
bytes32 constant MAIN_DOMAIN_ID = bytes32(0x00);

contract GovernorNPOFixture is Test {
    // accounts
    address member1 = vm.addr(1);
    address member2 = vm.addr(2);
    address nonReputationHolder = vm.addr(3);
    address[] members = [member1, member2];

    // contracts
    GovernorNPO public governor;
    SBRTManager public manager;
    MockTarget public mockTarget;

    function setUp() public virtual {
        mockTarget = new MockTarget();
        governor = new GovernorNPO();
        manager = new SBRTManager(address(governor), "DOMAIN_1", "DOMAIN_1_ADMIN", members);
        governor.init(address(manager));
    }

    function testInitVotingSettings() public {
        assertEq(governor.name(), "GovernorNPO");
        assertEq(governor.votingDelay(), VOTING_DELAY);
        assertEq(governor.votingPeriod(), VOTING_PERIOD);
        assertEq(governor.proposalThreshold(), PROPOSAL_THRESHOLD);
    }
}

contract VotingTest is GovernorNPOFixture {
    bytes4 FUNC_SELECTOR = bytes4(keccak256("targetFunction(uint256)"));
    address[] targets;
    uint256[] values = [uint256(0)];
    bytes[] calldatas = [abi.encodePacked(FUNC_SELECTOR, uint256(123))];
    string description = "Proposal #1: test description";
    bytes32 descriptionHash = bytes32(keccak256(abi.encodePacked(description)));
    uint256 proposalId;

    function proposeInDomain() public {}

    function propose() public {}

    function setUp() public override {
        super.setUp();

        targets = [address(mockTarget)];
        proposalId = uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));

        vm.prank(member1);
        governor.propose(DOMAIN_1_ID, targets, values, calldatas, description);
    }

    function testInitProposalInfo() public {
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        assertEq(againstVotes, 0);
        assertEq(forVotes, 0);
        assertEq(abstainVotes, 0);
        assertEq(governor.hasVoted(proposalId, member1), false);
        // governor.state(proposalId); // 0 = pending
        assertEq(governor.proposalSnapshot(proposalId), block.number + VOTING_DELAY);
        assertEq(governor.proposalDeadline(proposalId), block.number + VOTING_DELAY + VOTING_PERIOD);
    }

    function testCastVote() public {
        governor.state(proposalId); // 0 = Pending
        vm.roll(block.number + VOTING_DELAY + 1);
        governor.state(proposalId); // 1 = Active
        vm.prank(member1);
        // 1 reputation(100) + 1 submission proposal score(10) = 110
        assertEq(governor.castVote(proposalId, 1, "test For vote"), 110);
        assertEq(governor.hasVoted(proposalId, member1), true);

        vm.prank(member2);
        // 1 reputation(100) = 100
        assertEq(governor.castVote(proposalId, 0, "test against vote"), 100);
        assertEq(governor.hasVoted(proposalId, member2), true);

        vm.roll(block.number + VOTING_DELAY + VOTING_PERIOD + 1);
        governor.state(proposalId); // 4 = Succeeded
    }

    function testExecute() public {
        vm.roll(block.number + VOTING_DELAY + 1);
        vm.prank(member1);
        assertEq(governor.castVote(proposalId, 1, "test For vote"), 110);
        vm.roll(block.number + VOTING_DELAY + VOTING_PERIOD + 1);
        governor.execute(targets, values, calldatas, descriptionHash);
        (uint256 state, address caller) = mockTarget.state();
        assertEq(state, 123);
        assertEq(caller, address(governor));
        governor.state(proposalId); // 7 = Executed
    }
}
