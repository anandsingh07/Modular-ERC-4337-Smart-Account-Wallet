// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SmartAccount {
    using ECDSA for bytes32;

    address public immutable OWNER;
    IEntryPoint public immutable ENTRY_POINT;
    uint256 public nonce;

    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;

    modifier onlyEntryPoint() {
        _onlyEntryPoint();
        _;
    }

    function _onlyEntryPoint() internal view {
        require(msg.sender == address(ENTRY_POINT), "not entrypoint");
    }

    constructor(address owner_, IEntryPoint entryPoint_) {
        require(owner_ != address(0), "invalid owner");
        require(address(entryPoint_) != address(0), "invalid entrypoint");

        OWNER = owner_;
        ENTRY_POINT = entryPoint_;
    }

    receive() external payable {}

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256) {
        require(userOp.nonce == nonce, "invalid nonce");

        address signer = userOpHash
            .toEthSignedMessageHash()
            .recover(userOp.signature);

        require(signer == OWNER, "invalid signature");

        unchecked {
            nonce++;
        }

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
        require(success, "execution failed");
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4) {
        address signer = hash
            .toEthSignedMessageHash()
            .recover(signature);

        return signer == OWNER ? EIP1271_MAGICVALUE : bytes4(0);
    }
}
