// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {AirdropV3} from "../src/AirdropV3.sol";
import {Proton} from "../src/token/proton.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract AirdropV2Test is Test {
    event ClaimedAirdrop(address account, uint256 amount);

    AirdropV3 public airdrop;
    Proton public proton;
    bytes32 public root = 0x3bb7189b47227b99e8282cf8ff5521b29fd3ac1628374fdcdbdab6634c9ed954;
    address public owner = makeAddr("owner");
    address public minter = makeAddr("minter");
    uint256 public privateAmount = 100e18;
    uint256 public publicAmount = 10e18;
    uint256 public duration = 1;
    uint256 public interval = 0.5 weeks;

    string name = "Proton Airdrop";
    string version = "0.0.3";

    // address user1 = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D;
    uint256 user1Priv;
    address caller;
    address user1 = 0xA7407106D3c9a5ab2131a7AcAa343b6219Aa1Dd6;
    address user2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user3 = 0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd;
    address user4 = 0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D;
    uint256 amount1 = 25000000000000000000;
    uint256 amount2 = 25000000000000000000;
    uint256 amount3 = 25000000000000000000;
    uint256 amount4 = 25000000000000000000;
    bytes32 proof11 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proof12 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32 proof21 = 0xc5012c6827e0226aa8862392d8ce0ae047cb9c3dfb5af51b81e585b3eea4ed7a;
    bytes32 proof22 = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32 proof31 = 0x4fd31fee0e75780cd67704fbc43caee70fddcaa43631e2e1bc9fb233fada2394;
    bytes32 proof32 = 0x80b56dc62d8ecdd3f329fe5bc221c944fa70e08fe12b61c352cc16b953bc4fc8;
    bytes32 proof41 = 0x0c7ef881bb675a5858617babe0eb12b538067e289d35d5b044ee76b79d335191;
    bytes32 proof42 = 0x80b56dc62d8ecdd3f329fe5bc221c944fa70e08fe12b61c352cc16b953bc4fc8;

    address[] public accounts = [user1, user2, user3, user4];
    uint256[] public amounts = [amount1, amount2, amount3, amount4];
    bytes32[][] public proofs = [[proof11, proof12], [proof21, proof22], [proof31, proof32], [proof41, proof42]];

    function setUp() public {
        vm.startPrank(owner);
        proton = new Proton();
        airdrop = new AirdropV3(name, version);
        airdrop.setAirdrop(root, proton, privateAmount, publicAmount, duration, interval);
        proton.setMinterAuthority(minter);
        vm.stopPrank();

        vm.prank(minter);
        proton.mint(address(airdrop), 110e18);

        // caller = makeAddr("caller");
        // (user1, user1Priv) = makeAddrAndKey("user");
    }

    function test_constructionV3() public view {
        assertEq(address(airdrop.getAirdropToken()), address(IERC20(proton)));
        assertEq(airdrop.getMerkleRoot(), root);
        assertEq(proton.balanceOf(address(airdrop)), 110e18);
        assertEq(airdrop.privatePhaseAmount(), 100e18);
        assertEq(airdrop.publicPhaseAmount(), 10e18);
        assertEq(airdrop.timeDuration(), 1 weeks + 1);
        assertEq(airdrop.interval(), 0.5 weeks);
        assert(airdrop.getPhase() == AirdropV3.PHASE.PRIVATE);
    }

    function test_UserCanClaimV3() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = proof11;
        proof[1] = proof12;
        vm.prank(user1);
        vm.expectEmit(address(airdrop));
        emit ClaimedAirdrop(user1, amount1);
        airdrop.claimAirdrop(amount1, proof);

        assertTrue(airdrop.hasClaimed(user1));
        assertEq(proton.balanceOf(user1), 25e18);
    }

    function test_UserCanClaimAfterClaimV3() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = proof11;
        proof[1] = proof12;
        vm.prank(user1);
        vm.expectEmit(address(airdrop));
        emit ClaimedAirdrop(user1, amount1);
        airdrop.claimAirdrop(amount1, proof);

        assertTrue(airdrop.hasClaimed(user1));
        assertEq(proton.balanceOf(user1), 25e18);

        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimAirdrop(amount1, proof);
    }

    function test_UserCanNotClaimAfterPhaseChangeV3() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = proof11;
        proof[1] = proof12;

        vm.warp(block.timestamp + 1 weeks + 1);
        assert(airdrop.getPhase() == AirdropV3.PHASE.PRIVATE);
        airdrop.performUpkeep("");
        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimAirdrop(amount1, proof);

        assert(airdrop.getPhase() == AirdropV3.PHASE.PUBLIC);
    }

    function test_UserCanClaimWithWrongProofV3() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = proof21;
        proof[1] = proof12;
        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimAirdrop(amount1, proof);
    }

    function test_UserCanClaimWithWrongAmountV3() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = proof11;
        proof[1] = proof12;
        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimAirdrop(amount2 + 1, proof);
    }

    function test_PhaseChangeAmount() public {
        assertEq(airdrop.publicPhaseAmount(), 10e18);
        assertEq(airdrop.privatePhaseAmount(), 100e18);

        bytes32[] memory proof1 = new bytes32[](2);
        proof1[0] = proof11;
        proof1[1] = proof12;
        vm.prank(user1);
        vm.expectEmit(address(airdrop));
        emit ClaimedAirdrop(user1, amount1);
        airdrop.claimAirdrop(amount1, proof1);

        assertTrue(airdrop.hasClaimed(user1));
        assertEq(proton.balanceOf(user1), 25e18);

        bytes32[] memory proof2 = new bytes32[](2);
        proof2[0] = proof21;
        proof2[1] = proof22;

        vm.warp(block.timestamp + 1 weeks + 1);
        assert(airdrop.getPhase() == AirdropV3.PHASE.PRIVATE);
        airdrop.performUpkeep("");
        vm.prank(user2);
        vm.expectRevert();
        airdrop.claimAirdrop(amount2, proof2);

        assert(airdrop.getPhase() == AirdropV3.PHASE.PUBLIC);

        assertEq(airdrop.publicPhaseAmount(), 85e18);
        assertEq(airdrop.privatePhaseAmount(), 0);
    }

    function test_GeneralUserCanClaim() public {
        assertEq(airdrop.publicPhaseAmount(), 10e18);
        assertEq(airdrop.privatePhaseAmount(), 100e18);

        bytes32[] memory proof1 = new bytes32[](2);
        proof1[0] = proof11;
        proof1[1] = proof12;
        vm.prank(user1);
        vm.expectEmit(address(airdrop));
        emit ClaimedAirdrop(user1, amount1);
        airdrop.claimAirdrop(amount1, proof1);

        assertTrue(airdrop.hasClaimed(user1));
        assertEq(proton.balanceOf(user1), 25e18);

        bytes32[] memory proof2 = new bytes32[](2);
        proof2[0] = proof21;
        proof2[1] = proof22;

        vm.warp(block.timestamp + 1 weeks + 1);
        assert(airdrop.getPhase() == AirdropV3.PHASE.PRIVATE);
        airdrop.performUpkeep("");
        vm.prank(user2);
        vm.expectRevert();
        airdrop.claimAirdrop(amount2, proof2);

        assert(airdrop.getPhase() == AirdropV3.PHASE.PUBLIC);

        assertEq(airdrop.publicPhaseAmount(), 85e18);
        assertEq(airdrop.privatePhaseAmount(), 0);

        address[] memory people = new address[](10);

        for (uint256 i = 0; i < people.length; i++) {
            people[i] = address(uint160(i + 1));
        }

        for (uint256 i = 0; i < people.length; i++) {
            vm.prank(people[i]);
            airdrop.claim();
        }

        vm.prank(people[0]);
        vm.expectRevert();
        airdrop.claim();

        assertEq(proton.balanceOf(people[0]), 1e18);
        assertEq(proton.balanceOf(people[1]), 1e18);
        assertEq(proton.balanceOf(people[2]), 1e18);
        assertEq(proton.balanceOf(people[3]), 1e18);
        assertEq(proton.balanceOf(people[4]), 1e18);
        assertEq(proton.balanceOf(people[4]), 1e18);

        assertEq(airdrop.publicPhaseAmount(), 75e18);
    }
}
