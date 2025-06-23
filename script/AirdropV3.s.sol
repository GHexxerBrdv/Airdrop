// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {AirdropV3} from "../src/AirdropV3.sol";

contract DeployAirdropV3 is Script {
    AirdropV3 airdrop;
    string name = "Proton Airdrop";
    string version = "0.0.3";

    function run() external returns (AirdropV3) {
        vm.startBroadcast();
        airdrop = new AirdropV3(name, version);
        vm.stopBroadcast();

        return airdrop;
    }
}
