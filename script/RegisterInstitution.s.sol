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
    // Expected VeridocsFactory address (same across all chains)
    address constant VERIDOCS_FACTORY_ADDRESS = 0xc81e0B078De7d58449454b18115616a6a6365A1C;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (address registryAddress) {
        uint256 chainId = block.chainid;
        console2.log("Registering institution on chain ID:", chainId);
        console2.log("Using VeridocsFactory at:", VERIDOCS_FACTORY_ADDRESS);

        // Institution details
        string memory institutionName = vm.envString("INSTITUTION_NAME");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");

        require(bytes(institutionName).length > 0, "INSTITUTION_NAME environment variable required");
        require(adminAddress != address(0), "ADMIN_ADDRESS environment variable required");

        VeridocsFactory factory = VeridocsFactory(VERIDOCS_FACTORY_ADDRESS);

        // Get the factory owner (this script must be run by the factory owner)
        address factoryOwner = factory.owner();
        address deployer = vm.addr(privateKey);

        console2.log("Factory owner:", factoryOwner);
        console2.log("Script runner:", deployer);
        console2.log("Institution admin address:", adminAddress);
        console2.log("Institution name:", institutionName);

        // Verify the deployer is the factory owner
        require(deployer == factoryOwner, "Only factory owner can register institutions");

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Register the institution and get the registry address
        registryAddress = factory.registerInstitution(adminAddress, institutionName);

        vm.stopBroadcast();

        console2.log("Institution registered successfully!");
        console2.log("Registry contract deployed at:", registryAddress);

        // Verify the registry
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);
        console2.log("Registry admin:", registry.admin());
        console2.log("Registry name:", registry.institutionName());
        console2.log("Registry agent count:", registry.getAgentCount());

        // Verify factory recognizes the registry
        assertTrue(factory.isInstitutionRegistered(registryAddress), "Factory should recognize the registry");

        // Display factory statistics
        (uint256 totalInstitutions, address owner) = factory.getFactoryStats();
        console2.log("\nFactory Statistics:");
        console2.log("- Total institutions:", totalInstitutions);
        console2.log("- Factory owner:", owner);

        // Show institution details
        (address admin, string memory name, bool isRegistered) = factory.getInstitutionDetails(registryAddress);
        console2.log("\nInstitution Details:");
        console2.log("- Admin:", admin);
        console2.log("- Name:", name);
        console2.log("- Is registered:", isRegistered);

        console2.log("\nNext steps:");
        console2.log("1. The admin can add agents using: addAgent(address agent)");
        console2.log(
            "2. Admin/agents can issue documents using: issueDocument(string cid) or issueDocumentWithMetadata(string cid, string metadata)"
        );
        console2.log("3. Anyone can verify documents using: verifyDocument(string cid)");
        console2.log("4. Admin can manage agents using: addAgent(address) and revokeAgent(address)");

        return registryAddress;
    }

    function assertTrue(bool condition, string memory message) internal pure {
        require(condition, message);
    }
}

// Example usage:
// INSTITUTION_NAME="University of Example" ADMIN_ADDRESS="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266" forge script
// script/RegisterInstitution.s.sol --rpc-url localhost --broadcast
