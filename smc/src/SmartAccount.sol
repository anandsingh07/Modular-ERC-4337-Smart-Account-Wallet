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

    bytes4 internal constant EIP1271_MAGICVALUE = 0x1626ba7e;

    mapping(address => uint256) public nonces;
    mapping(address => SessionKey) public sessionKeys;

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
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);

        require(userOp.nonce == nonces[signer], "invalid nonce");

        if (signer != OWNER) {
            SessionKey storage sk = sessionKeys[signer];

            require(sk.expiry != 0, "invalid session key");
            require(block.timestamp <= sk.expiry, "session expired");
            require(sk.used < sk.maxUses, "session usage exceeded");

            bytes4 selector = bytes4(userOp.callData[0:4]);
            require(selector == sk.selector, "invalid selector");

            address target = address(bytes20(userOp.callData[4:24]));
            require(target == sk.target, "invalid target");

            sk.used++;
        }

        nonces[signer]++;

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

    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) external onlyEntryPoint {
        uint256 length = targets.length;
        require(
            length == values.length && length == data.length,
            "length mismatch"
        );

        for (uint256 i = 0; i < length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(data[i]);
            require(success, "batch execution failed");
        }
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4) {
        address signer = hash.toEthSignedMessageHash().recover(signature);

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
