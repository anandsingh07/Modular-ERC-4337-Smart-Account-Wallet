// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { SmartAccount } from "./SmartAccount.sol";

contract SmartAccountFactory {
    IEntryPoint public immutable ENTRY_POINT;

    event AccountCreated(
        address indexed account,
        address indexed owner,
        bytes32 indexed salt
    );

    constructor(IEntryPoint entryPoint_) {
        require(address(entryPoint_) != address(0), "invalid entrypoint");
        ENTRY_POINT = entryPoint_;
    }

    function createAccount(
        address owner,
        bytes32 salt
    ) external returns (address account) {
        require(owner != address(0), "invalid owner");

        
        require(
            msg.sender == owner || msg.sender == address(ENTRY_POINT),
            "unauthorized deployer"
        );

        bytes32 finalSalt = keccak256(
            abi.encode(owner, salt, block.chainid)
        );

        account = getAddress(owner, salt);

        if (account.code.length > 0) {
            return account;
        }

        account = address(
            new SmartAccount{salt: finalSalt}(owner, ENTRY_POINT)
        );

        emit AccountCreated(account, owner, finalSalt);
    }

    function getAddress(
        address owner,
        bytes32 salt
    ) public view returns (address) {
        bytes32 finalSalt = keccak256(
            abi.encode(owner, salt, block.chainid)
        );

        bytes memory creationCode = abi.encodePacked(
            type(SmartAccount).creationCode,
            abi.encode(owner, ENTRY_POINT)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                finalSalt,
                keccak256(creationCode)
            )
        );

        return address(uint160(uint256(hash)));
    }
}
