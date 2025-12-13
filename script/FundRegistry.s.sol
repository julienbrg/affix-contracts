// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";

/**
 * @title FundRegistry
 * @notice Script to fund a registry contract with 0.0001 ETH
 * @dev Sends 0.0001 ETH to the specified registry address
 */
contract FundRegistry is Script {
    uint256 constant FUND_AMOUNT = 0.0001 ether;
    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        uint256 chainId = block.chainid;
        console2.log("Funding registry on chain ID:", chainId);
        console2.log("Network:", getNetworkName(chainId));

        // Get the registry address from environment variable
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        require(registryAddress != address(0), "REGISTRY_ADDRESS environment variable required");

        console2.log("Registry address:", registryAddress);
        console2.log("Fund amount:", FUND_AMOUNT, "wei (0.0001 ETH)");

        // Get the sender address
        address sender = vm.addr(privateKey);
        console2.log("Sender address:", sender);

        // Check sender balance
        uint256 senderBalance = sender.balance;
        console2.log("Sender balance:", senderBalance, "wei");
        require(senderBalance >= FUND_AMOUNT, "Insufficient balance to fund registry");

        // Check registry balance before funding
        uint256 registryBalanceBefore = registryAddress.balance;
        console2.log("Registry balance before:", registryBalanceBefore, "wei");

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Send ETH to the registry
        (bool success,) = payable(registryAddress).call{ value: FUND_AMOUNT }("");
        require(success, "Failed to send ETH to registry");

        vm.stopBroadcast();

        // Check registry balance after funding
        uint256 registryBalanceAfter = registryAddress.balance;
        console2.log("Registry balance after:", registryBalanceAfter, "wei");
        console2.log("Increase:", registryBalanceAfter - registryBalanceBefore, "wei");

        console2.log("\n=== Funding Complete ===");
        console2.log("Registry at", registryAddress, "successfully funded with", FUND_AMOUNT, "wei");
        console2.log("Explorer URL:", getExplorerUrl(chainId, registryAddress));
    }

    function getNetworkName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 11_155_111) return "Sepolia Testnet";
        if (chainId == 137) return "Polygon Mainnet";
        if (chainId == 80_001) return "Polygon Mumbai";
        if (chainId == 10) return "Optimism Mainnet";
        if (chainId == 420) return "Optimism Goerli";
        if (chainId == 42_161) return "Arbitrum One";
        if (chainId == 421_613) return "Arbitrum Goerli";
        if (chainId == 8453) return "Base Mainnet";
        if (chainId == 84_531) return "Base Goerli";
        if (chainId == 314_159) return "Filecoin Calibration";
        if (chainId == 314) return "Filecoin Mainnet";
        return "Unknown Network";
    }

    function getExplorerUrl(uint256 chainId, address contractAddress) internal pure returns (string memory) {
        string memory addressStr = addressToString(contractAddress);

        if (chainId == 1) {
            return string(abi.encodePacked("https://etherscan.io/address/", addressStr));
        } else if (chainId == 11_155_111) {
            return string(abi.encodePacked("https://sepolia.etherscan.io/address/", addressStr));
        } else if (chainId == 137) {
            return string(abi.encodePacked("https://polygonscan.com/address/", addressStr));
        } else if (chainId == 80_001) {
            return string(abi.encodePacked("https://mumbai.polygonscan.com/address/", addressStr));
        } else if (chainId == 10) {
            return string(abi.encodePacked("https://optimistic.etherscan.io/address/", addressStr));
        } else if (chainId == 420) {
            return string(abi.encodePacked("https://goerli-optimism.etherscan.io/address/", addressStr));
        } else if (chainId == 42_161) {
            return string(abi.encodePacked("https://arbiscan.io/address/", addressStr));
        } else if (chainId == 421_613) {
            return string(abi.encodePacked("https://goerli.arbiscan.io/address/", addressStr));
        } else if (chainId == 8453) {
            return string(abi.encodePacked("https://basescan.org/address/", addressStr));
        } else if (chainId == 84_531) {
            return string(abi.encodePacked("https://goerli.basescan.org/address/", addressStr));
        } else if (chainId == 314_159) {
            return string(abi.encodePacked("https://calibration.filscan.io/address/", addressStr));
        } else if (chainId == 314) {
            return string(abi.encodePacked("https://filscan.io/address/", addressStr));
        }

        return "Unknown explorer";
    }

    function addressToString(address addr) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(addr)));
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}
