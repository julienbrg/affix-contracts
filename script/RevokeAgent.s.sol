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
    address constant VERIDOCS_FACTORY_ADDRESS = 0x3f7e9f20878521B8AF089209E83263ee7CF3a0a1;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        uint256 chainId = block.chainid;
        console2.log("Revoking agent on chain ID:", chainId);

        // Agent details from environment
        address agentAddress = vm.envAddress("AGENT_ADDRESS");
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");

        require(agentAddress != address(0), "AGENT_ADDRESS environment variable required");
        require(registryAddress != address(0), "REGISTRY_ADDRESS environment variable required");

        VeridocsFactory factory = VeridocsFactory(VERIDOCS_FACTORY_ADDRESS);

        // Get the caller address (should be the admin)
        address caller = vm.addr(privateKey);
        console2.log("Caller address:", caller);
        console2.log("Registry address:", registryAddress);
        console2.log("Agent address to revoke:", agentAddress);

        // Verify the registry is registered with the factory
        require(factory.isInstitutionRegistered(registryAddress), "Registry not registered with factory");

        // Get registry details and verify caller is admin
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);
        address registryAdmin = registry.admin();

        console2.log("Registry admin:", registryAdmin);
        console2.log("Institution name:", registry.institutionName());
        console2.log("Current agent count:", registry.getAgentCount());

        // Verify the caller is indeed the admin of the registry
        require(registry.admin() == caller, "Caller is not the registry admin");

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
// AGENT_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8" REGISTRY_ADDRESS="0x..." forge script script/RevokeAgent.s.sol --rpc-url localhost --broadcast
