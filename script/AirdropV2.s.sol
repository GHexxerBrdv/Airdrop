// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {AirdropV2} from "../src/AirdropV2.sol";
import {Proton} from "../src/token/proton.sol";
import {ProtonScript} from "../script/Proton.s.sol";

contract AirdropV2Script is Script {
    AirdropV2 public airdrop;
    Proton public airdropToken;
    ProtonScript public deployer;
    string name = "Proton Airdrop";
    string version = "0.0.2";
    bytes32 public root = 0x80b56dc62d8ecdd3f329fe5bc221c944fa70e08fe12b61c352cc16b953bc4fc8;

    function run() external returns (AirdropV2) {
        deployer = new ProtonScript();
        airdropToken = deployer.run();
        vm.startBroadcast();
        airdrop = new AirdropV2(name, version, root, airdropToken);
        vm.stopBroadcast();

        return airdrop;
    }
}
