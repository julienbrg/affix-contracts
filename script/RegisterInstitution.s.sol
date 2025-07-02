// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title RegisterInstitution
 * @notice Script to register an institution with the VeridocsFactory
 * @dev Creates a new VeridocsRegistry for the institution
 * @notice Only the factory owner can register new institutions
 */
contract RegisterInstitution is Script {
    // UPDATED: Filecoin Calibration VeridocsFactory address
    address constant VERIDOCS_FACTORY_ADDRESS = 0x1928Fb336C74432e129142c7E3ee57856486eFfa;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (address registryAddress) {
        uint256 chainId = block.chainid;
        console2.log("Registering institution on chain ID:", chainId);
        console2.log("Network:", getNetworkName(chainId));
        console2.log("Using VeridocsFactory at:", VERIDOCS_FACTORY_ADDRESS);

        // Institution details
        string memory institutionName = vm.envString("INSTITUTION_NAME");
        string memory institutionUrl = vm.envString("INSTITUTION_URL");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");

        require(bytes(institutionName).length > 0, "INSTITUTION_NAME environment variable required");
        require(bytes(institutionUrl).length > 0, "INSTITUTION_URL environment variable required");
        require(adminAddress != address(0), "ADMIN_ADDRESS environment variable required");

        // Check if factory exists at expected address
        uint256 factoryCodeSize;
        assembly {
            factoryCodeSize := extcodesize(VERIDOCS_FACTORY_ADDRESS)
        }
        require(factoryCodeSize > 0, "VeridocsFactory not deployed at expected address. Please deploy factory first.");

        VeridocsFactory factory = VeridocsFactory(VERIDOCS_FACTORY_ADDRESS);

        // Get the factory owner (this script must be run by the factory owner)
        address factoryOwner = factory.owner();
        address deployer = vm.addr(privateKey);

        console2.log("Factory owner:", factoryOwner);
        console2.log("Script runner:", deployer);
        console2.log("Institution admin address:", adminAddress);
        console2.log("Institution name:", institutionName);
        console2.log("Institution URL:", institutionUrl);

        // Verify the deployer is the factory owner
        require(deployer == factoryOwner, "Only factory owner can register institutions");

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Register the institution and get the registry address
        registryAddress = factory.registerInstitution(adminAddress, institutionName, institutionUrl);

        vm.stopBroadcast();

        console2.log("Institution registered successfully!");
        console2.log("Registry contract deployed at:", registryAddress);

        // Verify the registry
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);
        console2.log("Registry admin:", registry.admin());
        console2.log("Registry name:", registry.institutionName());
        console2.log("Registry URL:", registry.institutionUrl());
        console2.log("Registry agent count:", registry.getAgentCount());

        // Verify factory recognizes the registry
        assertTrue(factory.isInstitutionRegistered(registryAddress), "Factory should recognize the registry");

        // Display factory statistics
        (uint256 totalInstitutions, address owner) = factory.getFactoryStats();
        console2.log("\nFactory Statistics:");
        console2.log("- Total institutions:", totalInstitutions);
        console2.log("- Factory owner:", owner);

        // Show institution details
        (address admin, string memory name, string memory url, bool isRegistered) = factory.getInstitutionDetails(
            registryAddress
        );
        console2.log("\nInstitution Details:");
        console2.log("- Admin:", admin);
        console2.log("- Name:", name);
        console2.log("- URL:", url);
        console2.log("- Is registered:", isRegistered);

        // Show network-specific explorer links
        console2.log("\nExplorer Links:");
        console2.log("- Factory:", getExplorerUrl(chainId, VERIDOCS_FACTORY_ADDRESS));
        console2.log("- Registry:", getExplorerUrl(chainId, registryAddress));

        console2.log("\nNext steps:");
        console2.log("1. The admin can add agents using: addAgent(address agent)");
        console2.log(
            "2. Admin/agents can issue documents using: issueDocument(string cid) or issueDocumentWithMetadata(string cid, string metadata)"
        );
        console2.log("3. Anyone can verify documents using: verifyDocument(string cid)");
        console2.log("4. Admin can manage agents using: addAgent(address) and revokeAgent(address)");
        console2.log(
            "5. Admin can update institution details using: updateInstitutionName(string) and updateInstitutionUrl(string)"
        );

        console2.log("\nEnvironment variables for next scripts:");
        console2.log("export REGISTRY_ADDRESS=", registryAddress);
        console2.log("export ADMIN_ADDRESS=", adminAddress);

        return registryAddress;
    }

    function assertTrue(bool condition, string memory message) internal pure {
        require(condition, message);
    }

    function getNetworkName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 11_155_111) return "Sepolia Testnet";
        if (chainId == 137) return "Polygon Mainnet";
        if (chainId == 80001) return "Polygon Mumbai";
        if (chainId == 10) return "Optimism Mainnet";
        if (chainId == 420) return "Optimism Goerli";
        if (chainId == 42161) return "Arbitrum One";
        if (chainId == 421613) return "Arbitrum Goerli";
        if (chainId == 8453) return "Base Mainnet";
        if (chainId == 84531) return "Base Goerli";
        if (chainId == 314159) return "Filecoin Calibration";
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
        } else if (chainId == 80001) {
            return string(abi.encodePacked("https://mumbai.polygonscan.com/address/", addressStr));
        } else if (chainId == 10) {
            return string(abi.encodePacked("https://optimistic.etherscan.io/address/", addressStr));
        } else if (chainId == 420) {
            return string(abi.encodePacked("https://goerli-optimism.etherscan.io/address/", addressStr));
        } else if (chainId == 42161) {
            return string(abi.encodePacked("https://arbiscan.io/address/", addressStr));
        } else if (chainId == 421613) {
            return string(abi.encodePacked("https://goerli.arbiscan.io/address/", addressStr));
        } else if (chainId == 8453) {
            return string(abi.encodePacked("https://basescan.org/address/", addressStr));
        } else if (chainId == 84531) {
            return string(abi.encodePacked("https://goerli.basescan.org/address/", addressStr));
        } else if (chainId == 314159) {
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
