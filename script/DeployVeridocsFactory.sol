// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";

/**
 * @title DeployVeridocsFactory
 * @notice Enhanced deployment script with automatic Etherscan verification
 * @dev Deploys and verifies the VeridocsFactory contract on Sepolia
 */
contract DeployVeridocsFactory is Script {
    // Safe Singleton Factory address - same on all EVM chains
    address constant SAFE_SINGLETON_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;

    // Salt for CREATE2 deployment
    bytes32 constant SALT = keccak256(bytes("VERIDOCS_DOCUMENT_FACTORY_V1"));

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (address VeridocsFactoryAddress) {
        uint256 chainId = block.chainid;
        console2.log("Deploying VeridocsFactory on chain ID:", chainId);
        console2.log("Using Safe Singleton Factory at:", SAFE_SINGLETON_FACTORY);

        // Get the deployer address (this will be the factory owner)
        address deployer = vm.addr(privateKey);
        console2.log("Deployer/Future Factory Owner:", deployer);

        // Get the creation code for VeridocsFactory with constructor parameters
        bytes memory VeridocsFactoryCreationCode = abi.encodePacked(
            type(VeridocsFactory).creationCode,
            abi.encode(deployer) // Constructor parameter: initialOwner
        );
        console2.log("VeridocsFactory creation code length:", VeridocsFactoryCreationCode.length, "bytes");

        // Compute the expected address for VeridocsFactory
        address expectedVeridocsFactory = calculateCreate2Address(SALT, keccak256(VeridocsFactoryCreationCode));
        console2.log("Expected VeridocsFactory address:", expectedVeridocsFactory);

        // Check if contract is already deployed
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(expectedVeridocsFactory)
        }

        bool isNewDeployment = false;

        if (codeSize > 0) {
            console2.log("VeridocsFactory already deployed at:", expectedVeridocsFactory);

            // Verify ownership
            VeridocsFactory existingFactory = VeridocsFactory(expectedVeridocsFactory);
            address currentOwner = existingFactory.owner();
            console2.log("Current factory owner:", currentOwner);

            if (currentOwner == deployer) {
                console2.log(" Factory owner is correct");
            } else {
                console2.log(" Factory owner mismatch - expected:", deployer, "actual:", currentOwner);
            }

            VeridocsFactoryAddress = expectedVeridocsFactory;
        } else {
            // Start broadcasting with the private key
            vm.startBroadcast(privateKey);

            // Deploy VeridocsFactory using Safe Singleton Factory
            (bool success, bytes memory returnData) = SAFE_SINGLETON_FACTORY.call(
                abi.encodePacked(SALT, VeridocsFactoryCreationCode)
            );

            require(success, "VeridocsFactory deployment failed");

            // Parse the returned address
            VeridocsFactoryAddress = bytesToAddress(returnData);
            console2.log("VeridocsFactory deployed at:", VeridocsFactoryAddress);

            // Verify deployment
            require(VeridocsFactoryAddress == expectedVeridocsFactory, "Deployed address mismatch");
            console2.log("Deployment verified successfully!");

            vm.stopBroadcast();

            isNewDeployment = true;
        }

        // Verify ownership is set correctly
        VeridocsFactory factory = VeridocsFactory(VeridocsFactoryAddress);
        address factoryOwner = factory.owner();
        console2.log("Factory owner set to:", factoryOwner);

        if (factoryOwner == deployer) {
            console2.log(" Ownership correctly set to deployer");
        } else {
            console2.log(" Ownership mismatch - expected:", deployer, "actual:", factoryOwner);
        }

        // Manual verification instructions for Sepolia
        if (isNewDeployment && chainId == 11155111) {
            console2.log("\n=== Etherscan Verification Instructions ===");
            console2.log("Run this command to verify the contract:");
            console2.log("");
            console2.log("forge verify-contract", VeridocsFactoryAddress, "src/VeridocsFactory.sol:VeridocsFactory \\");
            console2.log("  --chain-id", chainId, "\\");
            console2.log("  --constructor-args", vm.toString(abi.encode(deployer)), "\\");
            console2.log("  --etherscan-api-key $API_KEY_ETHERSCAN");
            console2.log("");
        }

        console2.log("\nDeployment Summary:");
        console2.log("- Chain ID:", chainId);
        console2.log("- VeridocsFactory:", VeridocsFactoryAddress);
        console2.log("- Factory Owner:", factoryOwner);
        console2.log("- Salt used:", vm.toString(SALT));

        if (chainId == 11155111) {
            console2.log("- Etherscan URL: https://sepolia.etherscan.io/address/", VeridocsFactoryAddress);
        }

        console2.log("\nNext steps:");
        console2.log("1. Verify the contract using the command above");
        console2.log("2. Register institutions using: registerInstitution(address admin, string name)");

        return VeridocsFactoryAddress;
    }

    function calculateCreate2Address(bytes32 salt, bytes32 bytecodeHash) internal pure returns (address) {
        return
            address(
                uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), SAFE_SINGLETON_FACTORY, salt, bytecodeHash))))
            );
    }

    function bytesToAddress(bytes memory data) internal pure returns (address) {
        require(data.length == 20, "Invalid address length");
        address addr;
        assembly {
            addr := mload(add(data, 20))
        }
        return addr;
    }
}
