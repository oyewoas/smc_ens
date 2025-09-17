// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Ens} from "../src/Ens.sol";

contract DeployEns is Script {
    Ens public ens;

    function setUp() public {}

    function run() public returns (Ens) {
        vm.startBroadcast();

        ens = new Ens();

        vm.stopBroadcast();

        return ens;
    }
}
