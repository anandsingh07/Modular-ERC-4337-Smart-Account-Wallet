// SPDX-License-Identifer:MIT 
pragma solidity ^0.8.23 ;

import "../lib/forge-std/src/Script.sol";
import "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import "../src/SmartAccount.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        EntryPoint entryPoint = new EntryPoint();

        SmartAccount account = new SmartAccount(
            msg.sender,
            IEntryPoint(address(entryPoint))
        );

        vm.stopBroadcast();
    }
}