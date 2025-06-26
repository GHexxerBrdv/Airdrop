// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {Proton} from "../src/token/proton.sol";
import {AirdropV2} from "../src/AirdropV2.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract DeployContracts is Script {
    address public proton;
    address public airdrop;

    bytes32 public root = 0x80b56dc62d8ecdd3f329fe5bc221c944fa70e08fe12b61c352cc16b953bc4fc8;

    function run() external {
        proton = DevOpsTools.get_most_recent_deployment("Proton", block.chainid);
        airdrop = DevOpsTools.get_most_recent_deployment("AirdropV2", block.chainid);

        console2.log(proton);
        console2.log(airdrop);

        vm.startBroadcast();
        Proton(proton).mint(airdrop, 100e18);
        vm.stopBroadcast();

        console2.log(Proton(proton).balanceOf(airdrop));
    }
}

contract ClaimAirdrop is Script {
    bytes32 proof1 = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32[] proof = [proof1];
    uint256 amount = 25000000000000000000;

    function run() external {
        address deployment = DevOpsTools.get_most_recent_deployment("AirdropV2", block.chainid);
        address proton = DevOpsTools.get_most_recent_deployment("Proton", block.chainid);

        vm.startBroadcast(vm.envUint("PRIV1"));
        AirdropV2(deployment).claimAirdrop(amount, proof);
        vm.stopBroadcast();

        console2.log(Proton(proton).balanceOf(vm.envAddress("ACC1")));
    }
}
