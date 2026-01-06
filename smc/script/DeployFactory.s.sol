// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import { SmartAccountFactory } from "../src/SmartAccountFactory.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address entryPoint = vm.envAddress("ENTRYPOINT");

        require(entryPoint != address(0), "ENTRYPOINT not set");

        vm.startBroadcast(deployerKey);

        SmartAccountFactory factory =
            new SmartAccountFactory(IEntryPoint(entryPoint));

        vm.stopBroadcast();

        console.log("Chain ID:", block.chainid);
        console.log("EntryPoint:", entryPoint);
        console.log("SmartAccountFactory deployed at:", address(factory));
    }
}

