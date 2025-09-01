// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.24;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { AffixFactory } from "../src/AffixFactory.sol";
import { AffixRegistry } from "../src/AffixRegistry.sol";

/**
 * @title RegisterEntity
 * @notice Script to register an entity with the AffixFactory
 * @dev Creates a new AffixRegistry for the entity
 * @notice Only the factory owner can register new entities
 */
contract RegisterEntity is Script {
    // UPDATED: Filecoin Calibration AffixFactory address
    address constant AFFIX_FACTORY_ADDRESS = 0x4C4D5C40D5D1c3F32724e8bef14b406F01b5eea6;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (address registryAddress) {
        uint256 chainId = block.chainid;
        console2.log("Registering entity on chain ID:", chainId);
        console2.log("Network:", getNetworkName(chainId));
        console2.log("Using AffixFactory at:", AFFIX_FACTORY_ADDRESS);

        // Entity details
        string memory entityName = vm.envString("ENTITY_NAME");
        string memory entityUrl = vm.envString("ENTITY_URL");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");

        require(bytes(entityName).length > 0, "ENTITY_NAME environment variable required");
        require(bytes(entityUrl).length > 0, "ENTITY_URL environment variable required");
        require(adminAddress != address(0), "ADMIN_ADDRESS environment variable required");

        // Check if factory exists at expected address
        uint256 factoryCodeSize;
        assembly {
            factoryCodeSize := extcodesize(AFFIX_FACTORY_ADDRESS)
        }
        require(factoryCodeSize > 0, "Please deploy factory first.");

        AffixFactory factory = AffixFactory(AFFIX_FACTORY_ADDRESS);

        // Get the factory owner (this script must be run by the factory owner)
        address factoryOwner = factory.owner();
        address deployer = vm.addr(privateKey);

        console2.log("Factory owner:", factoryOwner);
        console2.log("Script runner:", deployer);
        console2.log("Entity admin address:", adminAddress);
        console2.log("Entity name:", entityName);
        console2.log("Entity URL:", entityUrl);

        // Verify the deployer is the factory owner
        require(deployer == factoryOwner, "Only factory owner can register entities");

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Register the entity and get the registry address
        registryAddress = factory.registerEntity(adminAddress, entityName, entityUrl);

        vm.stopBroadcast();

        console2.log("Entity registered successfully!");
        console2.log("Registry contract deployed at:", registryAddress);

        // Verify the registry
        AffixRegistry registry = AffixRegistry(registryAddress);
        console2.log("Registry admin:", registry.admin());
        console2.log("Registry name:", registry.entityName());
        console2.log("Registry URL:", registry.entityUrl());
        console2.log("Registry agent count:", registry.getAgentCount());

        // Verify factory recognizes the registry
        assertTrue(factory.isEntityRegistered(registryAddress), "Factory should recognize the registry");

        // Display factory statistics
        (uint256 totalEntities, address owner) = factory.getFactoryStats();
        console2.log("\nFactory Statistics:");
        console2.log("- Total entities:", totalEntities);
        console2.log("- Factory owner:", owner);

        // Show entity details
        (address admin, string memory name, string memory url, bool isRegistered) = factory.getEntityDetails(
            registryAddress
        );
        console2.log("\nEntity Details:");
        console2.log("- Admin:", admin);
        console2.log("- Name:", name);
        console2.log("- URL:", url);
        console2.log("- Is registered:", isRegistered);

        // Show network-specific explorer links
        console2.log("\nExplorer Links:");
        console2.log("- Factory:", getExplorerUrl(chainId, AFFIX_FACTORY_ADDRESS));
        console2.log("- Registry:", getExplorerUrl(chainId, registryAddress));

        console2.log("\nNext steps:");
        console2.log("1. The admin can add agents using: addAgent(address agent)");
        console2.log(
            "2. Admin/agents can issue documents using: issueDocument(string cid) or issueDocumentWithMetadata(string cid, string metadata)"
        );
        console2.log("3. Anyone can verify documents using: verifyDocument(string cid)");
        console2.log("4. Admin can manage agents using: addAgent(address) and revokeAgent(address)");
        console2.log("5. Admin can update entity details using: updateEntityName(string) and updateEntityUrl(string)");

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
