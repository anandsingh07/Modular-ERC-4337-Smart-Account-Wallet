// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SmartAccount {
    using ECDSA for bytes32;

    struct SessionKey {
        address target;
        bytes4 selector;
        uint48 expiry;
        uint48 maxUses;
        uint48 used;
    }

    address public immutable OWNER;
    IEntryPoint public immutable ENTRY_POINT;
    uint256 public nonce;

    mapping(address => SessionKey) public sessionKeys;

    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;

    modifier onlyEntryPoint() {
        require(msg.sender == address(ENTRY_POINT), "not entrypoint");
        _;
    }

    constructor(address owner_, IEntryPoint entryPoint_) {
        require(owner_ != address(0), "invalid owner");
        require(address(entryPoint_) != address(0), "invalid entrypoint");
        OWNER = owner_;
        ENTRY_POINT = entryPoint_;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                          SESSION KEYS
    //////////////////////////////////////////////////////////////*/

    function addSessionKey(
        address key,
        address target,
        bytes4 selector,
        uint48 expiry,
        uint48 maxUses
    ) external {
        require(msg.sender == OWNER, "only owner");
        require(expiry > block.timestamp, "invalid expiry");

        sessionKeys[key] = SessionKey(
            target,
            selector,
            expiry,
            maxUses,
            0
        );
    }

    function revokeSessionKey(address key) external {
        require(msg.sender == OWNER, "only owner");
        delete sessionKeys[key];
    }

    /*//////////////////////////////////////////////////////////////
                        ERC-4337 VALIDATION
    //////////////////////////////////////////////////////////////*/

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256) {
        require(userOp.nonce == nonce, "invalid nonce");

        address signer =
            userOpHash.toEthSignedMessageHash().recover(userOp.signature);

        if (signer != OWNER) {
            SessionKey storage sk = sessionKeys[signer];

            require(sk.expiry != 0, "invalid session key");
            require(block.timestamp <= sk.expiry, "session expired");
            require(sk.used < sk.maxUses, "usage exceeded");

            (address to,, bytes memory innerData) =
                abi.decode(userOp.callData[4:], (address, uint256, bytes));

            require(to == sk.target, "invalid target");
            require(bytes4(innerData) == sk.selector, "invalid selector");

            sk.used++;
        }

        nonce++;

        if (missingAccountFunds > 0) {
            (bool ok, ) =
                payable(msg.sender).call{value: missingAccountFunds}("");
            require(ok, "funds transfer failed");
        }

        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                            EXECUTION
    //////////////////////////////////////////////////////////////*/

    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyEntryPoint {
        (bool success, ) = to.call{value: value}(data);
        require(success, "execution failed");
    }

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) external onlyEntryPoint {
        require(
            targets.length == values.length &&
            values.length == data.length,
            "length mismatch"
        );

        for (uint256 i; i < targets.length; i++) {
            (bool success, ) =
                targets[i].call{value: values[i]}(data[i]);
            require(success, "batch failed");
        }
    }

    /*//////////////////////////////////////////////////////////////
                           EIP-1271
    //////////////////////////////////////////////////////////////*/

    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4) {
        address signer =
            hash.toEthSignedMessageHash().recover(signature);

        if (signer == OWNER) return EIP1271_MAGICVALUE;

        SessionKey memory sk = sessionKeys[signer];
        if (
            sk.expiry != 0 &&
            block.timestamp <= sk.expiry &&
            sk.used < sk.maxUses
        ) {
            return EIP1271_MAGICVALUE;
        }

        return bytes4(0);
    }
}
