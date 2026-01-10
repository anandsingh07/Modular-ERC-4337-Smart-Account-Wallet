// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IPaymaster } from "account-abstraction/interfaces/IPaymaster.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract AuthPaymaster is IPaymaster, Ownable {
    using ECDSA for bytes32;

   

    struct PaymasterData {
        uint48 deadline;            
        bytes32 approvalNonce;      
        address target;             
        bytes signature;            
    }



    IEntryPoint public immutable ENTRY_POINT;

    address public authSigner;             
    bool public paused;
    uint256 public maxCallGasLimit;

    mapping(bytes32 => bool) public usedApprovals;
    mapping(address => bool) public allowedTargets;

   

    error NotEntryPoint();
    error InvalidSignature();
    error ApprovalExpired();
    error ApprovalAlreadyUsed();
    error GasLimitExceeded();
    error TargetNotAllowed();
    error PaymasterPaused();

    constructor(
        IEntryPoint entryPoint_,
        address authSigner_,
        uint256 maxCallGasLimit_
    ) {
        ENTRY_POINT = entryPoint_;
        authSigner = authSigner_;
        maxCallGasLimit = maxCallGasLimit_;
        _transferOwnership(msg.sender);
    }

    

    modifier onlyEntryPoint() {
        if (msg.sender != address(ENTRY_POINT)) revert NotEntryPoint();
        _;
    }

    modifier notPaused() {
        if (paused) revert PaymasterPaused();
        _;
    }

    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256
    )
        external
        override
        onlyEntryPoint
        notPaused
        returns (bytes memory context, uint256 validationData)
    {
    
        uint256 callGasLimit = uint256(userOp.accountGasLimits >> 128);
        if (callGasLimit > maxCallGasLimit) revert GasLimitExceeded();

        PaymasterData memory data =
            abi.decode(userOp.paymasterAndData[20:], (PaymasterData));

        if (block.timestamp > data.deadline) revert ApprovalExpired();
        if (usedApprovals[data.approvalNonce]) revert ApprovalAlreadyUsed();

    
        if (!allowedTargets[data.target]) revert TargetNotAllowed();

        
        bytes32 digest = keccak256(
            abi.encode(
                userOpHash,
                data.deadline,
                data.approvalNonce,
                data.target,
                callGasLimit,
                block.chainid,
                address(this)
            )
        ).toEthSignedMessageHash();

        if (digest.recover(data.signature) != authSigner) {
            revert InvalidSignature();
        }

    
        context = abi.encode(data.approvalNonce);

        
        validationData = uint256(data.deadline) << 160;
    }


    function postOp(
        IPaymaster.PostOpMode mode,
        bytes calldata context,
        uint256,
        uint256
    ) external override onlyEntryPoint {
        if (mode == IPaymaster.PostOpMode.opSucceeded) {
            bytes32 approvalNonce = abi.decode(context, (bytes32));
            usedApprovals[approvalNonce] = true;
        }
    }


    function setAuthSigner(address newSigner) external onlyOwner {
        authSigner = newSigner;
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
    }

    function setMaxCallGas(uint256 gasLimit) external onlyOwner {
        maxCallGasLimit = gasLimit;
    }

    function setTarget(address target, bool allowed) external onlyOwner {
        allowedTargets[target] = allowed;
    }



    function deposit() external payable {
        ENTRY_POINT.depositTo{value: msg.value}(address(this));
    }

    function withdrawTo(address to, uint256 amount) external onlyOwner {
        ENTRY_POINT.withdrawTo(payable(to), amount);
    }

    function getDeposit() external view returns (uint256) {
        return ENTRY_POINT.balanceOf(address(this));
    }
}
