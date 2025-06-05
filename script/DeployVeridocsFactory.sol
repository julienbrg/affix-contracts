// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";

/**
 * @title DeployVeridocsFactory
 * @notice Deploys the VeridocsFactory contract using the Safe Singleton Factory
 * @dev Uses CREATE2 to ensure deterministic deployment addresses across chains
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

        // Get the creation code for VeridocsFactory
        bytes memory VeridocsFactoryCreationCode = type(VeridocsFactory).creationCode;
        console2.log("VeridocsFactory creation code length:", VeridocsFactoryCreationCode.length, "bytes");

        // Compute the expected address for VeridocsFactory
        address expectedVeridocsFactory = calculateCreate2Address(SALT, keccak256(VeridocsFactoryCreationCode));
        console2.log("Expected VeridocsFactory address:", expectedVeridocsFactory);

        // Check if contract is already deployed
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(expectedVeridocsFactory)
        }

        if (codeSize > 0) {
            console2.log("VeridocsFactory already deployed at:", expectedVeridocsFactory);
            return expectedVeridocsFactory;
        }

        // Start broadcasting with the private key
        vm.startBroadcast(privateKey);

        // Deploy VeridocsFactory using Safe Singleton Factory
        (bool success, bytes memory returnData) =
            SAFE_SINGLETON_FACTORY.call(abi.encodePacked(SALT, VeridocsFactoryCreationCode));

        require(success, "VeridocsFactory deployment failed");

        // Parse the returned address
        VeridocsFactoryAddress = bytesToAddress(returnData);
        console2.log("VeridocsFactory deployed at:", VeridocsFactoryAddress);

        // Verify deployment
        require(VeridocsFactoryAddress == expectedVeridocsFactory, "Deployed address mismatch");
        console2.log("Deployment verified successfully!");

        vm.stopBroadcast();

        console2.log("\nDeployment Summary:");
        console2.log("- Chain ID:", chainId);
        console2.log("- VeridocsFactory:", VeridocsFactoryAddress);
        console2.log("- Salt used:", vm.toString(SALT));
        console2.log("\nNext steps:");
        console2.log("1. Deploy this same contract on other chains using the same command");
        console2.log("2. The contract will have the same address on all chains");
        console2.log("3. Institutions can register using: registerInstitution(string name)");

        return VeridocsFactoryAddress;
    }

    function calculateCreate2Address(bytes32 salt, bytes32 bytecodeHash) internal pure returns (address) {
        return address(
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
