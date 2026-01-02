// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IEntryPoint } from "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ECDSA } from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract SmartAccount {
    using ECDSA for bytes32;

    address public owner;
    IEntryPoint public immutable ENTRY_POINT;
    uint256 public nonce;

    modifier onlyEntryPoint() {
        _onlyEntryPoint();
        _;
    }

    function _onlyEntryPoint() internal view {
        require(msg.sender == address(ENTRY_POINT), "Not EntryPoint");
    }

    constructor(address _owner, IEntryPoint _entryPoint) {
        owner = _owner;
        ENTRY_POINT = _entryPoint;
    }

    receive() external payable {}

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);
        require(signer == owner, "Invalid signature");

        nonce++;

        if (missingAccountFunds > 0) {
            payable(msg.sender).transfer(missingAccountFunds);
        }

        return 0;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyEntryPoint {
        (bool success, ) = to.call{value: value}(data);
        require(success, "Execution failed");
    }
}
