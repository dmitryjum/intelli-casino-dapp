// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {IntelliCasinoBetting} from "../src/IntelliCasinoBetting.sol";
import {Script, console} from "forge-std/Script.sol";

contract IntelliCasinoBettingDeploymentScript is Script {
  IntelliCasinoBetting public betting;

  function run() public {
    vm.createSelectFork(vm.rpcUrl("local")); //networks are specified in foundry.toml and local private key should be used
    // vm.createSelectFork(vm.rpcUrl("sepolia")); // ether the personal private key or vanity wallet should be used and should have the sepolia funds on it
    uint privateKey = vm.envUint("PRIVATE_KEY");
    address owner = vm.addr(privateKey);
    vm.startBroadcast(privateKey);

    betting = new IntelliCasinoBetting(owner);

    vm.stopBroadcast();
  }
}