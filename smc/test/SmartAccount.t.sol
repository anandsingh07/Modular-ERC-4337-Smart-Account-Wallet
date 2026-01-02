// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/SmartAccount.sol";
import "../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract SmartAccountTest is Test {
    SmartAccount account;

    address owner;
    uint256 ownerKey;
    address entryPoint;

    function setUp() public {
        ownerKey = 0xA11CE;
        owner = vm.addr(ownerKey);
        entryPoint = address(0x1111);
        account = new SmartAccount(owner, IEntryPoint(entryPoint));
    }

    function testValidateUserOpValidSignature() public {
        PackedUserOperation memory op;
        op.sender = address(account);

        bytes32 userOpHash = keccak256("userOp");
        bytes32 ethHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethHash);
        op.signature = abi.encodePacked(r, s, v);

        vm.prank(entryPoint);
        uint256 res = account.validateUserOp(op, userOpHash, 0);

        assertEq(res, 0);
        assertEq(account.nonce(), 1);
    }

    function testValidateUserOpRejectsInvalidSigner() public {
        PackedUserOperation memory op;
        bytes32 userOpHash = keccak256("bad");

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1234, userOpHash);
        op.signature = abi.encodePacked(r, s, v);

        vm.prank(entryPoint);
        vm.expectRevert();
        account.validateUserOp(op, userOpHash, 0);
    }

    function testExecuteOnlyEntryPoint() public {
        vm.expectRevert();
        account.execute(address(0), 0, "");
    }
}
