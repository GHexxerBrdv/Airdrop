// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Proton} from "../src/token/proton.sol";
import {AirdropV3} from "../src/AirdropV3.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract InteractionV3 is Script {
    address public proton;
    address public airdrop;
    uint256 privatePhaseAmount = 8e18;
    uint256 publicPhaseAmount = 2e18;
    uint256 duration = 10;
    uint256 interval = 2;

    bytes32 public root = 0x48914914a3d84bc56742f0f5223422cd95d66279e260e0d1728d3fa75aa9cfab;

    function run() external {
        proton = DevOpsTools.get_most_recent_deployment("Proton", block.chainid);
        airdrop = DevOpsTools.get_most_recent_deployment("AirdropV3", block.chainid);

        console2.log(proton);
        console2.log(airdrop);

        vm.startBroadcast();
        // AirdropV3(airdrop).setAirdrop(root, IERC20(proton), privatePhaseAmount, publicPhaseAmount, duration);
        Proton(proton).mint(airdrop, 10e18);
        vm.stopBroadcast();

        console2.log(Proton(proton).balanceOf(airdrop));
        console2.log(AirdropV3(airdrop).privatePhaseAmount());
        console2.log(AirdropV3(airdrop).timeDuration());
    }
}

contract AirdropClaim is Script {
    bytes32 proof11 = 0xb6c2b77b66f8dc54e43e8b86df18d9b42ec014140a868cc2c62e91fdc3b038a4;
    bytes32 proof12 = 0xcacc4321590279c65806336bf0de0efd6489f3e11713b61eae11588537794d7e;
    bytes32[] proof1 = [proof11, proof12];
    uint256 amount1 = 2000000000000000000;
    bytes32 proof21 = 0xf0bc05b8a0b08bf685394dcfeafe865ae9b9754f097549eac06e34a8af8ddf2f;
    bytes32 proof22 = 0xcacc4321590279c65806336bf0de0efd6489f3e11713b61eae11588537794d7e;
    bytes32[] proof2 = [proof21, proof22];
    uint256 amount2 = 3000000000000000000;
    bytes32 proof31 = 0xd39f314e275a80c5a67a608dace9d2122b03884fc01d268d0f386e631c9805b1;
    bytes32 proof32 = 0x92629d8c288cef16ab76c0277ee596d8bc8ea578bb6a0af623677bea0e04bda2;
    bytes32[] proof3 = [proof31, proof32];
    uint256 amount3 = 1000000000000000000;

    function run() external {
        address proton = DevOpsTools.get_most_recent_deployment("Proton", block.chainid);
        address airdrop = DevOpsTools.get_most_recent_deployment("AirdropV3", block.chainid);

        vm.startBroadcast();
        AirdropV3(airdrop).claimAirdrop(amount3, proof3);
        vm.stopBroadcast();

        console2.log(Proton(proton).balanceOf(0xA7407106D3c9a5ab2131a7AcAa343b6219Aa1Dd6));
        console2.log(Proton(proton).balanceOf(0x54DC75df46f1d1F8fe1a0Fd5E2d86Fe1A9B30D1a));
        console2.log(Proton(proton).balanceOf(0x97118108D8E46F9E8Bd37B9C77aaf9d4b485D30e));
    }
}

contract ViewState is Script {
    function run() external {
        address proton = DevOpsTools.get_most_recent_deployment("Proton", block.chainid);
        address airdrop = DevOpsTools.get_most_recent_deployment("AirdropV3", block.chainid);

        console2.log(AirdropV3(airdrop).publicPhaseAmount());
        assert(AirdropV3(airdrop).getPhase() == AirdropV3.PHASE.PUBLIC);

        vm.startBroadcast();
        AirdropV3(airdrop).claim();
        vm.stopBroadcast();

        console2.log(Proton(proton).balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
        console2.log(Proton(proton).balanceOf(0x9a581eeEfE4bed5D61a5A709CDFc704347A820bF));
        console2.log(Proton(proton).balanceOf(0x365fDe3d307DE9daE8b7588F8Aa52D2293CfB7f0));
    }
}
