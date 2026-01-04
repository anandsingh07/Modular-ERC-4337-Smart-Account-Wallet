// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import { SmartAccountFactory } from "../src/SmartAccountFactory.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract DeployFactory is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address entryPoint = vm.envAddress("ENTRYPOINT");

        vm.startBroadcast(deployerKey);

        SmartAccountFactory factory =
            new SmartAccountFactory(IEntryPoint(entryPoint));

        vm.stopBroadcast();

        console.log("SmartAccountFactory deployed at:", address(factory));
    }
}
