// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {AirdropV3} from "../src/AirdropV3.sol";
import {Proton} from "../src/token/proton.sol";
import {ProtonScript} from "../script/Proton.s.sol";

contract DeployAirdropV3 is Script {
    AirdropV3 airdrop;
    string name = "Proton Airdrop";
    string version = "0.0.3";

    bytes32 public root = 0x48914914a3d84bc56742f0f5223422cd95d66279e260e0d1728d3fa75aa9cfab;
    Proton public proton;
    ProtonScript public deployer;
    uint256 privatePhaseAmount = 8e18;
    uint256 publicPhaseAmount = 2e18;
    uint256 duration = 10;

    function run() external returns (AirdropV3) {
        deployer = new ProtonScript();
        proton = deployer.run();
        vm.startBroadcast();
        airdrop = new AirdropV3(name, version, root, proton, privatePhaseAmount, publicPhaseAmount, duration);
        vm.stopBroadcast();

        return airdrop;
    }
}
