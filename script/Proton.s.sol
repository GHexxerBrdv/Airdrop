// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {Proton} from "../src/token/proton.sol";

contract ProtonScript is Script {
    Proton p;

    function run() external returns (Proton) {
        vm.startBroadcast();
        p = new Proton();
        vm.stopBroadcast();
        return p;
    }
}
