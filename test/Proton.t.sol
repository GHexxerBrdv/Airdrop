// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Proton} from "../src/token/proton.sol";
import {Test, console2} from "forge-std/Test.sol";

contract ProtonTest is Test {
    Proton public proton;
    address public owner = makeAddr("owner");
    address public minter = makeAddr("minter");

    function setUp() public {
        vm.startPrank(owner);
        proton = new Proton();
        proton.setMinterAuthority(minter);
        vm.stopPrank();
        vm.prank(minter);
        proton.mint(owner, 1e6 * 1e18);
    }

    function test_construction() public view {
        console2.log("The address of Proton", address(proton));
        assertEq(minter, proton.getMinterAuthority());
        assertEq(proton.balanceOf(owner), 1e6 * 1e18);
    }

    function test_nonOwnerOperations() public {
        address hacker = makeAddr("hacker");

        vm.startPrank(hacker);
        vm.expectRevert();
        proton.mint(hacker, 1e18);
        vm.expectRevert();
        proton.setMinterAuthority(hacker);
        vm.stopPrank();
    }

    function test_ownerOperations() public {
        vm.startPrank(owner);
        vm.expectRevert();
        proton.setMinterAuthority(address(0));
        vm.stopPrank();

        vm.startPrank(minter);
        vm.expectRevert();
        proton.mint(address(0), 1e18);
        vm.expectRevert();
        proton.mint(address(1), 0);
        vm.stopPrank();
    }
}
