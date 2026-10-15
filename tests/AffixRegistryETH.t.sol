// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import { Test, console } from "forge-std/src/Test.sol";
import { AffixRegistry } from "../src/AffixRegistry.sol";

/**
 * @title AffixRegistryETHTest
 * @notice Tests ETH receiving and withdrawal functionality for EIP-7702 delegation sponsorship
 * @dev Verifies that AffixRegistry can receive ETH and admin can withdraw it
 */
contract AffixRegistryETHTest is Test {
    AffixRegistry public registry;

    address public admin = address(0x1);
    address public agent = address(0x2);
    address public user = address(0x3);

    string constant TEST_ENTITY_NAME = "Test University";
    string constant TEST_ENTITY_URL = "https://testuniversity.edu";

    event EthReceived(address indexed sender, uint256 amount);
    event EthWithdrawn(address indexed recipient, uint256 amount);

    function setUp() public {
        registry = new AffixRegistry(admin, TEST_ENTITY_NAME, TEST_ENTITY_URL);

        // Fund test accounts
        vm.deal(user, 100 ether);
        vm.deal(agent, 100 ether);
    }

    function testReceiveETHDirectTransfer() public {
        uint256 amount = 1 ether;

        // Check initial balance
        assertEq(address(registry).balance, 0, "Initial balance should be 0");

        // Expect EthReceived event
        vm.expectEmit(true, false, false, true);
        emit EthReceived(user, amount);

        // Send ETH directly to the contract
        vm.prank(user);
        (bool success,) = address(registry).call{ value: amount }("");
        assertTrue(success, "ETH transfer should succeed");

        // Verify balance updated
        assertEq(address(registry).balance, amount, "Contract should have received ETH");
    }

    function testReceiveETHViaTransfer() public {
        uint256 amount = 2 ether;

        // Expect EthReceived event
        vm.expectEmit(true, false, false, true);
        emit EthReceived(user, amount);

        // Send ETH using transfer
        vm.prank(user);
        payable(address(registry)).transfer(amount);

        // Verify balance
        assertEq(address(registry).balance, amount, "Contract should have received ETH via transfer");
    }

    function testReceiveETHViaSend() public {
        uint256 amount = 0.5 ether;

        // Expect EthReceived event
        vm.expectEmit(true, false, false, true);
        emit EthReceived(user, amount);

        // Send ETH using send
        vm.prank(user);
        // solhint-disable-next-line check-send-result
        bool success = payable(address(registry)).send(amount);
        assertTrue(success, "Send should succeed");

        // Verify balance
        assertEq(address(registry).balance, amount, "Contract should have received ETH via send");
    }

    function testReceiveMultipleDeposits() public {
        // Multiple users send ETH
        vm.prank(user);
        payable(address(registry)).transfer(1 ether);

        vm.prank(agent);
        payable(address(registry)).transfer(2 ether);

        vm.prank(admin);
        vm.deal(admin, 10 ether);
        payable(address(registry)).transfer(3 ether);

        // Total should be 6 ether
        assertEq(address(registry).balance, 6 ether, "Contract should have 6 ETH from multiple deposits");
    }

    function testWithdrawSponsorFunds() public {
        // Deposit ETH first
        vm.prank(user);
        payable(address(registry)).transfer(5 ether);

        uint256 adminBalanceBefore = admin.balance;
        uint256 withdrawAmount = 2 ether;

        // Expect EthWithdrawn event
        vm.expectEmit(true, false, false, true);
        emit EthWithdrawn(admin, withdrawAmount);

        // Admin withdraws
        vm.prank(admin);
        registry.withdrawSponsorFunds(withdrawAmount);

        // Verify balances
        assertEq(address(registry).balance, 3 ether, "Contract should have 3 ETH remaining");
        assertEq(admin.balance, adminBalanceBefore + withdrawAmount, "Admin should have received 2 ETH");
    }

    function testWithdrawAllSponsorFunds() public {
        // Deposit ETH
        vm.prank(user);
        payable(address(registry)).transfer(10 ether);

        uint256 adminBalanceBefore = admin.balance;
        uint256 contractBalance = address(registry).balance;

        // Admin withdraws all by passing address(this).balance
        vm.prank(admin);
        registry.withdrawSponsorFunds(contractBalance);

        // Verify balances
        assertEq(address(registry).balance, 0, "Contract should have 0 ETH");
        assertEq(admin.balance, adminBalanceBefore + contractBalance, "Admin should have received all ETH");
    }

    function testOnlyOwnerCanWithdraw() public {
        // Deposit ETH
        vm.prank(user);
        payable(address(registry)).transfer(5 ether);

        // Non-owner tries to withdraw
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user));
        vm.prank(user);
        registry.withdrawSponsorFunds(1 ether);

        // Non-owner agent tries to withdraw
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", agent));
        vm.prank(agent);
        registry.withdrawSponsorFunds(1 ether);

        // Contract balance should remain unchanged
        assertEq(address(registry).balance, 5 ether, "Balance should remain unchanged");
    }

    function testCannotWithdrawZeroAmount() public {
        // Deposit ETH
        vm.prank(user);
        payable(address(registry)).transfer(5 ether);

        // Try to withdraw 0
        vm.expectRevert("Amount must be greater than 0");
        vm.prank(admin);
        registry.withdrawSponsorFunds(0);
    }

    function testCannotWithdrawMoreThanBalance() public {
        // Deposit only 2 ETH
        vm.prank(user);
        payable(address(registry)).transfer(2 ether);

        // Try to withdraw 5 ETH
        vm.expectRevert("Insufficient balance");
        vm.prank(admin);
        registry.withdrawSponsorFunds(5 ether);
    }

    function testWithdrawFromEmptyContract() public {
        // No deposits, balance is 0

        // Try to withdraw
        vm.expectRevert("Insufficient balance");
        vm.prank(admin);
        registry.withdrawSponsorFunds(1 ether);
    }

    function testPartialWithdrawals() public {
        // Deposit 10 ETH
        vm.prank(user);
        payable(address(registry)).transfer(10 ether);

        uint256 adminBalanceBefore = admin.balance;

        // First withdrawal: 3 ETH
        vm.prank(admin);
        registry.withdrawSponsorFunds(3 ether);
        assertEq(address(registry).balance, 7 ether);
        assertEq(admin.balance, adminBalanceBefore + 3 ether);

        // Second withdrawal: 2 ETH
        vm.prank(admin);
        registry.withdrawSponsorFunds(2 ether);
        assertEq(address(registry).balance, 5 ether);
        assertEq(admin.balance, adminBalanceBefore + 5 ether);

        // Third withdrawal: remaining 5 ETH
        vm.prank(admin);
        registry.withdrawSponsorFunds(5 ether);
        assertEq(address(registry).balance, 0);
        assertEq(admin.balance, adminBalanceBefore + 10 ether);
    }

    function testReceiveETHWithCalldata() public {
        uint256 amount = 1 ether;

        // Send ETH with some calldata (triggers fallback)
        vm.expectEmit(true, false, false, true);
        emit EthReceived(user, amount);

        vm.prank(user);
        (bool success,) = address(registry).call{ value: amount }(abi.encodeWithSignature("nonExistentFunction()"));
        assertTrue(success, "Fallback should accept ETH");

        assertEq(address(registry).balance, amount, "Contract should have received ETH via fallback");
    }

    function testFuzzReceiveETH(uint256 amount) public {
        // Bound the amount to reasonable values
        vm.assume(amount > 0 && amount <= 1000 ether);

        // Fund user
        vm.deal(user, amount);

        // Send ETH
        vm.prank(user);
        payable(address(registry)).transfer(amount);

        // Verify
        assertEq(address(registry).balance, amount, "Contract should have received exact amount");
    }

    function testFuzzWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        // Bound amounts
        vm.assume(depositAmount > 0 && depositAmount <= 1000 ether);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);

        // Deposit
        vm.deal(user, depositAmount);
        vm.prank(user);
        payable(address(registry)).transfer(depositAmount);

        // Withdraw
        uint256 adminBalanceBefore = admin.balance;
        vm.prank(admin);
        registry.withdrawSponsorFunds(withdrawAmount);

        // Verify
        assertEq(address(registry).balance, depositAmount - withdrawAmount);
        assertEq(admin.balance, adminBalanceBefore + withdrawAmount);
    }

    function testGasUsageForReceive() public {
        uint256 amount = 1 ether;

        vm.prank(user);
        uint256 gasBefore = gasleft();
        payable(address(registry)).transfer(amount);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for receiving ETH:", gasUsed);

        // Should be very low gas (just event emission)
        assertLt(gasUsed, 50_000, "Receiving ETH should use minimal gas");
    }

    function testGasUsageForWithdraw() public {
        // Deposit first
        vm.prank(user);
        payable(address(registry)).transfer(5 ether);

        // Withdraw and measure gas
        vm.prank(admin);
        uint256 gasBefore = gasleft();
        registry.withdrawSponsorFunds(1 ether);
        uint256 gasUsed = gasBefore - gasleft();

        console.log("Gas used for withdrawing ETH:", gasUsed);

        // Withdrawal should be efficient
        assertLt(gasUsed, 100_000, "Withdrawing ETH should use reasonable gas");
    }
}
