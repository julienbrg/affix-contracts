// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title IssueDocument
 * @notice Script to issue a document using an institution's VeridocsRegistry
 * @dev The caller must be either the admin or an authorized agent
 */
contract IssueDocument is Script {
    // Expected VeridocsFactory address (same across all chains)
    address constant VERIDOCS_FACTORY_ADDRESS = 0xc81e0B078De7d58449454b18115616a6a6365A1C;

    uint256 privateKey = vm.envUint("PRIVATE_KEY");

    function run() public {
        uint256 chainId = block.chainid;
        console2.log("Issuing document on chain ID:", chainId);

        // Document details from environment
        string memory documentCid = vm.envString("DOCUMENT_CID");
        string memory metadata = vm.envOr("DOCUMENT_METADATA", string(""));
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");

        require(bytes(documentCid).length > 0, "DOCUMENT_CID environment variable required");
        require(registryAddress != address(0), "REGISTRY_ADDRESS environment variable required");

        VeridocsFactory factory = VeridocsFactory(VERIDOCS_FACTORY_ADDRESS);

        // Get the issuer address (could be admin or agent)
        address issuer = vm.addr(privateKey);
        console2.log("Issuer address:", issuer);
        console2.log("Registry address:", registryAddress);
        console2.log("Document CID:", documentCid);
        console2.log("Document metadata:", metadata);

        // Verify the registry is registered with the factory
        require(factory.isInstitutionRegistered(registryAddress), "Registry not registered with factory");

        // Get registry details
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);
        console2.log("Institution name:", registry.institutionName());
        console2.log("Registry admin:", registry.admin());

        // Check if issuer can issue documents
        require(registry.canIssueDocuments(issuer), "Issuer not authorized to issue documents");

        // Determine issuer role
        string memory issuerRole;
        if (issuer == registry.admin()) issuerRole = "admin";
        else if (registry.isAgent(issuer)) issuerRole = "agent";
        else revert("Issuer is not admin or authorized agent");

        console2.log("Issuer role:", issuerRole);

        // Start broadcasting
        vm.startBroadcast(privateKey);

        // Issue the document
        if (bytes(metadata).length > 0) {
            registry.issueDocumentWithMetadata(documentCid, metadata);
            console2.log("Document issued with metadata");
        } else {
            registry.issueDocument(documentCid);
            console2.log("Document issued");
        }

        vm.stopBroadcast();

        // Verify the document was issued
        (bool exists, uint256 timestamp, string memory institutionName) = registry.verifyDocument(documentCid);

        // Get full document details
        (
            bool existsDetails,
            uint256 timestampDetails,
            string memory institutionNameDetails,
            string memory metadataDetails,
            address issuedBy
        ) = registry.getDocumentDetails(documentCid);

        console2.log("\nDocument verification:");
        console2.log("- Exists:", exists);
        console2.log("- Timestamp:", timestamp);
        console2.log("- Institution:", institutionName);
        console2.log("- Metadata:", metadataDetails);
        console2.log("- Issued by:", issuedBy);
        console2.log("- Registry contract:", registryAddress);
        console2.log("- Total documents issued:", registry.getDocumentCount());

        console2.log("\nDocument issued successfully!");
    }
}

// Example usage:
// DOCUMENT_CID="QmExampleDocumentHash123" DOCUMENT_METADATA="Diploma in Computer Science"
// REGISTRY_ADDRESS="0x..." forge script script/IssueDocument.s.sol --rpc-url localhost --broadcast
