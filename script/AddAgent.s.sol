// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title AddAgent
 * @notice Script to add an agent to an institution's VeridocsRegistry
 * @dev The caller must be the registered admin of the institution
 */
contract AddAgent is Script {
    // Expected VeridocsFactory address (same across all chains)
    address constant VERIDOCS_FACTORY_ADDRESS = 0x6c5c8D8C5c44C8c5c8c5c8c5c8c5c8C5C8c5c8c5;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        uint256 chainId = block.chainid;
        console2.log("Adding agent on chain ID:", chainId);

        // Agent details from environment
        address agentAddress = vm.envAddress("AGENT_ADDRESS");
        require(agentAddress != address(0), "AGENT_ADDRESS environment variable required");

        VeridocsFactory factory = VeridocsFactory(VERIDOCS_FACTORY_ADDRESS);

        // Get the admin address
        address admin = vm.addr(privateKey);
        console2.log("Admin address:", admin);
        console2.log("Agent address to add:", agentAddress);

        // Check if admin is registered
        require(factory.isInstitutionRegistered(admin), "Admin not registered");

        // Get the registry address
        address registryAddress = factory.getInstitutionRegistry(admin);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        console2.log("Using registry at:", registryAddress);
        console2.log("Institution name:", registry.institutionName());
        console2.log("Current agent count:", registry.getAgentCount());

        // Check if agent is already added
        if (registry.isAgent(agentAddress)) {
            console2.log("Agent already exists in the registry");
            return;
        }

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Add the agent
        registry.addAgent(agentAddress);

        vm.stopBroadcast();

        // Verify the agent was added
        console2.log("\nAgent verification:");
        console2.log("- Is agent:", registry.isAgent(agentAddress));
        console2.log("- Can issue documents:", registry.canIssueDocuments(agentAddress));
        console2.log("- Total agents:", registry.getAgentCount());

        // Show all active agents
        address[] memory activeAgents = registry.getActiveAgents();
        console2.log("- Active agents:");
        for (uint256 i = 0; i < activeAgents.length; i++) {
            console2.log("  ", activeAgents[i]);
        }

        console2.log("\nAgent added successfully!");
        console2.log("The agent can now issue documents using issueDocument() or issueDocumentWithMetadata()");
    }
}

// Example usage:
// AGENT_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8" forge script script/AddAgent.s.sol --rpc-url localhost
// --broadcast
