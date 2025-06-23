// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {AirdropV2} from "../src/AirdropV2.sol";

contract AirdropV2Script is Script {
    AirdropV2 public airdrop;
    string name = "Proton Airdrop";
    string version = "0.0.2";

    function run() external returns (AirdropV2) {
        vm.startBroadcast();
        airdrop = new AirdropV2(name, version);
        vm.stopBroadcast();

        return airdrop;
    }
}
