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

    struct SessionKey {
        address target;
        bytes4 selector;
        uint48 expiry;
        uint48 maxUses;
        uint48 used;
    }

    mapping(address => SessionKey) public sessionKeys;

    function addSessionKey(
        address key,
        address target,
        bytes4 selector,
        uint48 expiry,
        uint48 maxUses
    ) external {
        require(msg.sender == OWNER, "only owner");
        require(key != address(0), "invalid key");
        require(target != address(0), "invalid target");
        require(expiry > block.timestamp, "invalid expiry");
        require(maxUses > 0, "invalid maxUses");

        sessionKeys[key] = SessionKey({
            target: target,
            selector: selector,
            expiry: expiry,
            maxUses: maxUses,
            used: 0
        });
    }

    function revokeSessionKey(address key) external {
        require(msg.sender == OWNER, "only owner");
        delete sessionKeys[key];
    }

    
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external onlyEntryPoint returns (uint256) {
        require(userOp.nonce == nonce, "invalid nonce");

        address signer = userOpHash
            .toEthSignedMessageHash()
            .recover(userOp.signature);

        if (signer != OWNER) {
            SessionKey storage sk = sessionKeys[signer];

            require(sk.expiry != 0, "invalid session key");
            require(block.timestamp <= sk.expiry, "session expired");
            require(sk.used < sk.maxUses, "session limit exceeded");

            bytes4 selector = bytes4(userOp.callData[0:4]);
            require(selector == sk.selector, "invalid selector");

            address target = abi.decode(userOp.callData[4:], (address));

            require(target == sk.target, "invalid target");

            sk.used++;
        }

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

        if (signer == OWNER) {
            return EIP1271_MAGICVALUE;
        }

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
