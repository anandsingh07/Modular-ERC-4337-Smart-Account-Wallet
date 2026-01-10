// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {  AuthPaymaster } from "../src/AuthPaymaster.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

contract DeployPaymaster is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        address entryPoint = vm.envAddress("ENTRYPOINT");
        address authSigner = vm.envAddress("AUTH_SIGNER");
        uint256 maxCallGas = vm.envUint("MAX_CALL_GAS");

        require(entryPoint != address(0), "ENTRYPOINT not set");
        require(authSigner != address(0), "AUTH_SIGNER not set");
        require(maxCallGas > 0, "MAX_CALL_GAS not set");

        vm.startBroadcast(deployerKey);

        AuthPaymaster paymaster =
            new AuthPaymaster(
                IEntryPoint(entryPoint),
                authSigner,
                maxCallGas
            );

        vm.stopBroadcast();

        console.log("Chain ID:", block.chainid);
        console.log("EntryPoint:", entryPoint);
        console.log("AuthSigner:", authSigner);
        console.log("Max Call Gas:", maxCallGas);
        console.log("AuthPaymasterV2 deployed at:", address(paymaster));
    }
}
