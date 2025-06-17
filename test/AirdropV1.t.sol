// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {AirdropV1} from "../src/AirdropV1.sol";
import {Proton} from "../src/token/proton.sol";

contract AirdropV1Test is Test {
    AirdropV1 airdrop;
    Proton proton;

    address owner = makeAddr("owner");

    function setUp() public {
        vm.startPrank(owner);
        proton = new Proton();
        airdrop = new AirdropV1(proton);
        proton.mint(address(airdrop), 1e6 * 1e18);
        vm.stopPrank();
    }

    function test_construction() public {
        assertEq(proton.balanceOf(address(airdrop)), 1e6 * 1e18);
        assertEq(proton.getMinterAuthority(), owner);
        assertEq(airdrop.getProton(), address(proton));
    }

    function test_setAddClaimer() public {
        uint256 nonce = 0;
        address[] memory claimers = new address[](100);
        uint256[] memory amounts = new uint256[](100);

        for (uint256 i = 0; i < claimers.length; i++) {
            uint256 amount = uint256(keccak256(abi.encodePacked(msg.sender, nonce++, block.prevrandao))) % 100;
            claimers[i] = address(uint160(i + 1));
            amounts[i] = amount * 1e18;
        }

        vm.prank(owner);
        airdrop.addClaimer(claimers, amounts);

        console2.log(airdrop.claimerToAmount(address(48)));
        uint256 balanceOFProtocol = proton.balanceOf(address(airdrop));

        vm.prank(address(48));
        airdrop.claimAirdrop();

        assertTrue(airdrop.hasClaimed(address(48)));
        uint256 balanceOfUser = proton.balanceOf(address(48));

        console2.log(balanceOfUser);

        vm.prank(address(48));
        vm.expectRevert();
        airdrop.claimAirdrop();

        assertEq(proton.balanceOf(address(airdrop)), balanceOFProtocol - balanceOfUser);
    }
}
