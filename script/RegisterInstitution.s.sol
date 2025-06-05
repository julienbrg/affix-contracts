// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title RegisterInstitution
 * @notice Script to register an institution with the VeridocsFactory
 * @dev Creates a new VeridocsRegistry for the institution with admin/agent system
 */
contract RegisterInstitution is Script {
    // Expected VeridocsFactory address (same across all chains)
    // This address is calculated using CREATE2 with the Safe Singleton Factory
    address constant VERIDOCS_FACTORY_ADDRESS = 0x3f7e9f20878521B8AF089209E83263ee7CF3a0a1;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public returns (address registryAddress) {
        uint256 chainId = block.chainid;
        console2.log("Registering institution on chain ID:", chainId);
        console2.log("Using VeridocsFactory at:", VERIDOCS_FACTORY_ADDRESS);

        // Institution details
        string memory institutionName = vm.envString("INSTITUTION_NAME");
        require(bytes(institutionName).length > 0, "INSTITUTION_NAME environment variable required");

        VeridocsFactory factory = VeridocsFactory(VERIDOCS_FACTORY_ADDRESS);

        // Get the deployer address (this will be the admin)
        address admin = vm.addr(privateKey);
        console2.log("Institution admin address:", admin);
        console2.log("Institution name:", institutionName);

        // Check if already registered
        if (factory.isInstitutionRegistered(admin)) {
            console2.log("Institution already registered!");
            registryAddress = factory.getInstitutionRegistry(admin);
            console2.log("Existing registry address:", registryAddress);
            return registryAddress;
        }

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Register the institution
        factory.registerInstitution(institutionName);

        vm.stopBroadcast();

        // Get the registry address
        registryAddress = factory.getInstitutionRegistry(admin);
        console2.log("Institution registered successfully!");
        console2.log("Registry contract deployed at:", registryAddress);

        // Verify the registry
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);
        console2.log("Registry admin:", registry.admin());
        console2.log("Registry name:", registry.institutionName());
        console2.log("Registry agent count:", registry.getAgentCount());

        console2.log("\nNext steps:");
        console2.log("1. Add agents using: addAgent(address agent)");
        console2.log(
            "2. Issue documents using: issueDocument(string cid) or issueDocumentWithMetadata(string cid, string metadata)"
        );
        console2.log("3. Verify documents using: verifyDocument(string cid)");
        console2.log("4. Manage agents using: addAgent(address) and revokeAgent(address)");

        return registryAddress;
    }
}

// Example usage:
// INSTITUTION_NAME="University of Example" forge script script/RegisterInstitution.s.sol --rpc-url localhost
// --broadcast
