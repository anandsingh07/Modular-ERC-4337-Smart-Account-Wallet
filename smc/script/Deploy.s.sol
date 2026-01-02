// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../lib/forge-std/src/Script.sol";
import "../lib/account-abstraction/contracts/core/EntryPoint.sol";
import "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import "../src/SmartAccount.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerKey);

        vm.startBroadcast(deployerKey);

        EntryPoint entryPoint = new EntryPoint();

        SmartAccount account = new SmartAccount(
            deployer,
            IEntryPoint(address(entryPoint))
        );

        vm.stopBroadcast();
    }
}
