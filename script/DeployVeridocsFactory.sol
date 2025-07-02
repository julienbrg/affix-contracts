// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";

/**
 * @title DeployVeridocsFactory
 * @notice Enhanced deployment script with automatic verification support
 * @dev Deploys the VeridocsFactory contract on multiple networks including Filecoin Calibration
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
        console2.log("Network name:", getNetworkName(chainId));
        console2.log("Using Safe Singleton Factory at:", SAFE_SINGLETON_FACTORY);

        // Get the deployer address (this will be the factory owner)
        address deployer = vm.addr(privateKey);
        console2.log("Deployer/Future Factory Owner:", deployer);

        // Set Filecoin-specific gas settings if needed
        if (isFilecoinNetwork(chainId)) {
            console2.log("Filecoin network detected - using higher gas settings");
            vm.txGasPrice(3_000_000_000); // 3 nanoFIL
        }

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

            if (currentOwner == deployer) console2.log(" Factory owner is correct");
            else console2.log(" Factory owner mismatch - expected:", deployer, "actual:", currentOwner);

            VeridocsFactoryAddress = expectedVeridocsFactory;
        } else {
            // Start broadcasting with the private key
            vm.startBroadcast(privateKey);

            // Deploy VeridocsFactory using Safe Singleton Factory with proper gas for Filecoin
            bytes memory callData = abi.encodePacked(SALT, VeridocsFactoryCreationCode);

            bool success;
            bytes memory returnData;
            if (isFilecoinNetwork(chainId)) {
                // Use higher gas limit for Filecoin networks
                (success, returnData) = SAFE_SINGLETON_FACTORY.call{ gas: 25_000_000 }(callData);
            } else {
                // Standard call for other networks
                (success, returnData) = SAFE_SINGLETON_FACTORY.call(callData);
            }

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

        if (factoryOwner == deployer) console2.log(" Ownership correctly set to deployer");
        else console2.log(" Ownership mismatch - expected:", deployer, "actual:", factoryOwner);

        // REMOVED: Automatic verification instructions - as requested
        if (isNewDeployment) {
            console2.log("\n=== Deployment Complete ===");
            console2.log("Automatic verification disabled as requested");
            console2.log("Contract deployed and functional at:", VeridocsFactoryAddress);
            console2.log("Explorer URL:", getExplorerUrl(chainId, VeridocsFactoryAddress));
        }

        console2.log("\nDeployment Summary:");
        console2.log("- Network:", getNetworkName(chainId));
        console2.log("- Chain ID:", chainId);
        console2.log("- VeridocsFactory:", VeridocsFactoryAddress);
        console2.log("- Factory Owner:", factoryOwner);
        console2.log("- Salt used:", vm.toString(SALT));
        console2.log("- Explorer URL:", getExplorerUrl(chainId, VeridocsFactoryAddress));

        if (isFilecoinNetwork(chainId)) {
            console2.log("- Gas settings: Optimized for Filecoin network");
        }

        console2.log("\nNext steps:");
        console2.log("1. Register institutions using: registerInstitution(address admin, string name, string url)");
        console2.log("2. Fund the deployer address with", getNetworkCurrency(chainId), "for transaction fees");

        return VeridocsFactoryAddress;
    }

    function isFilecoinNetwork(uint256 chainId) internal pure returns (bool) {
        return chainId == 314_159 || chainId == 314; // Calibration and Mainnet
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

    function getNetworkCurrency(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1 || chainId == 11_155_111) return "ETH";
        if (chainId == 137 || chainId == 80_001) return "MATIC";
        if (chainId == 10 || chainId == 420) return "ETH";
        if (chainId == 42_161 || chainId == 421_613) return "ETH";
        if (chainId == 8453 || chainId == 84_531) return "ETH";
        if (chainId == 314_159 || chainId == 314) return "tFIL";
        return "Native Token";
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
