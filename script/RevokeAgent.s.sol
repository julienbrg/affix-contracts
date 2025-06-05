// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title RevokeAgent
 * @notice Script to revoke an agent from an institution's VeridocsRegistry
 * @dev The caller must be the registered admin of the institution
 */
contract RevokeAgent is Script {
    // Expected VeridocsFactory address (same across all chains)
    address constant VERIDOCS_FACTORY_ADDRESS = 0x6c5c8D8C5c44C8c5c8c5c8c5c8c5c8C5C8c5c8c5;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        uint256 chainId = block.chainid;
        console2.log("Revoking agent on chain ID:", chainId);

        // Agent details from environment
        address agentAddress = vm.envAddress("AGENT_ADDRESS");
        require(agentAddress != address(0), "AGENT_ADDRESS environment variable required");

        VeridocsFactory factory = VeridocsFactory(VERIDOCS_FACTORY_ADDRESS);

        // Get the admin address
        address admin = vm.addr(privateKey);
        console2.log("Admin address:", admin);
        console2.log("Agent address to revoke:", agentAddress);

        // Check if admin is registered
        require(factory.isInstitutionRegistered(admin), "Admin not registered");

        // Get the registry address
        address registryAddress = factory.getInstitutionRegistry(admin);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        console2.log("Using registry at:", registryAddress);
        console2.log("Institution name:", registry.institutionName());
        console2.log("Current agent count:", registry.getAgentCount());

        // Check if agent exists
        if (!registry.isAgent(agentAddress)) {
            console2.log("Agent does not exist in the registry");
            return;
        }

        // Show current agents before revocation
        address[] memory agentsBefore = registry.getActiveAgents();
        console2.log("Active agents before revocation:");
        for (uint256 i = 0; i < agentsBefore.length; i++) {
            console2.log("  ", agentsBefore[i]);
        }

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Revoke the agent
        registry.revokeAgent(agentAddress);

        vm.stopBroadcast();

        // Verify the agent was revoked
        console2.log("\nAgent verification after revocation:");
        console2.log("- Is agent:", registry.isAgent(agentAddress));
        console2.log("- Can issue documents:", registry.canIssueDocuments(agentAddress));
        console2.log("- Total agents:", registry.getAgentCount());

        // Show remaining active agents
        address[] memory agentsAfter = registry.getActiveAgents();
        console2.log("- Active agents after revocation:");
        for (uint256 i = 0; i < agentsAfter.length; i++) {
            console2.log("  ", agentsAfter[i]);
        }

        console2.log("\nAgent revoked successfully!");
        console2.log("The agent can no longer issue documents for this institution");
    }
}

// Example usage:
// AGENT_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8" forge script script/RevokeAgent.s.sol --rpc-url localhost
// --broadcast
