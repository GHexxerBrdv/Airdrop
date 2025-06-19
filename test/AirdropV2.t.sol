// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {AirdropV2} from "../src/AirdropV2.sol";
import {Proton} from "../src/token/proton.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract AirdropV2Test is Test {
    event ClaimedAirdrop(address account, uint256 amount);

    AirdropV2 public airdrop;
    Proton public proton;
    bytes32 public root = 0x451ed1d017ba112a69b56d458c9fcb29f284e6a02aa82787c2f79ad62376a6d2;
    address public owner = makeAddr("owner");
    address public minter = makeAddr("minter");

    string name = "Proton Airdrop";
    string version = "0.0.1";

    // address user1 = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D;
    address user1;
    uint256 user1Priv;
    address caller;
    address user2 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address user3 = 0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd;
    address user4 = 0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D;
    uint256 amount1 = 15000000000000000000;
    uint256 amount2 = 75000000000000000000;
    uint256 amount3 = 17000000000000000000;
    uint256 amount4 = 19000000000000000000;

    function setUp() public {
        vm.startPrank(owner);
        proton = new Proton();
        airdrop = new AirdropV2(name, version);
        airdrop.setAirdrop(root, proton);
        proton.setMinterAuthority(minter);
        vm.stopPrank();

        vm.prank(minter);
        proton.mint(address(airdrop), 200e18);

        caller = makeAddr("caller");
        (user1, user1Priv) = makeAddrAndKey("user");
    }

    function test_constructionV2() public view {
        assertEq(address(airdrop.getAirdropToken()), address(IERC20(proton)));
        assertEq(airdrop.getMerkleRoot(), root);
        assertEq(proton.balanceOf(address(airdrop)), 200e18);
    }

    function test_UserCanClaim() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x05ad1f0ef71944d506af44fdfa0a67ff9ab1563becd9a81a6d6c9edeeaa9745b;
        proof[1] = 0x97aaa16f2d82ee950ffea417c76085716d62b5ab444ae3405cb1d299e0f79a37;
        vm.prank(user1);
        vm.expectEmit(address(airdrop));
        emit ClaimedAirdrop(user1, amount1);
        airdrop.claimAirdrop(amount1, proof);

        assertTrue(airdrop.hasClaimed(user1));
    }

    function test_UserCannotClaimAfterClaim() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x05ad1f0ef71944d506af44fdfa0a67ff9ab1563becd9a81a6d6c9edeeaa9745b;
        proof[1] = 0x97aaa16f2d82ee950ffea417c76085716d62b5ab444ae3405cb1d299e0f79a37;
        vm.prank(user1);
        vm.expectEmit(address(airdrop));
        emit ClaimedAirdrop(user1, amount1);
        airdrop.claimAirdrop(amount1, proof);

        assertTrue(airdrop.hasClaimed(user1));

        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimAirdrop(amount1, proof);
    }

    function test_UserCannotClaimWithWrongPrrof() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x05ad1f0ef71944d506af44fdfa0a67ff9ab1563becd9a81a6d6c9edeeaa9748b;
        proof[1] = 0x97aaa16f2d82ee950ffea417c76085716d62b5ab444ae3405cb1d299e0f79137;
        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimAirdrop(amount1, proof);

        assertFalse(airdrop.hasClaimed(user1));
    }

    function test_UserCannotClaimWithWrongAmount() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x05ad1f0ef71944d506af44fdfa0a67ff9ab1563becd9a81a6d6c9edeeaa9745b;
        proof[1] = 0x97aaa16f2d82ee950ffea417c76085716d62b5ab444ae3405cb1d299e0f79a37;
        vm.prank(user1);
        vm.expectRevert();
        airdrop.claimAirdrop(100e18, proof);

        assertFalse(airdrop.hasClaimed(user1));
    }

    function signMessage(uint256 privateKey, address permitted, address account)
        public
        view
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 messageHash = airdrop._messageHash(account, permitted, amount1);
        (v, r, s) = vm.sign(privateKey, messageHash);
    }

    function test_permitClaim() public {
        uint256 satrtingBalanceOfUser1 = proton.balanceOf(user1);

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x05ad1f0ef71944d506af44fdfa0a67ff9ab1563becd9a81a6d6c9edeeaa9745b;
        proof[1] = 0x97aaa16f2d82ee950ffea417c76085716d62b5ab444ae3405cb1d299e0f79a37;

        vm.prank(user1);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user1Priv, caller, user1);

        vm.prank(caller);
        airdrop.claimPermeet(user1, amount1, proof, v, r, s);

        uint256 endingBalanceOfUser1 = proton.balanceOf(user1);
        console.log("Ending balance:", endingBalanceOfUser1);
        assertEq(endingBalanceOfUser1 - satrtingBalanceOfUser1, amount1);
    }

    function test_CannotpermitClaimUnpermitted() public {
        uint256 satrtingBalanceOfUser1 = proton.balanceOf(user1);

        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x05ad1f0ef71944d506af44fdfa0a67ff9ab1563becd9a81a6d6c9edeeaa9745b;
        proof[1] = 0x97aaa16f2d82ee950ffea417c76085716d62b5ab444ae3405cb1d299e0f79a37;

        vm.prank(user1);
        (uint8 v, bytes32 r, bytes32 s) = signMessage(user1Priv, caller, user1);

        address hacker = makeAddr("hacker");

        vm.prank(hacker);
        vm.expectRevert();
        airdrop.claimPermeet(user1, amount1, proof, v, r, s);

        uint256 endingBalanceOfUser1 = proton.balanceOf(user1);
        console.log("Ending balance:", endingBalanceOfUser1);
        assertEq(satrtingBalanceOfUser1, 0);
    }
}
