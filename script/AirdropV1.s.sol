// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script} from "forge-std/Script.sol";
import {AirdropV1} from "../src/AirdropV1.sol";
import {Proton} from "../src/token/proton.sol";

contract AirdropV1Script is Script {
    AirdropV1 airdrop;
    Proton proton;
    uint256 constant deadline = 150;

    function run() external returns (AirdropV1) {
        vm.startBroadcast();
        proton = new Proton();
        airdrop = new AirdropV1(proton, deadline);
        vm.stopBroadcast();
        return airdrop;
    }
}
