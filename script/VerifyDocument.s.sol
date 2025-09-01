// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.24;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { AffixFactory } from "../src/AffixFactory.sol";
import { AffixRegistry } from "../src/AffixRegistry.sol";

/**
 * @title VerifyDocument
 * @notice Script to verify a document using an entity's AffixRegistry
 * @dev Anyone can verify documents - no authentication required
 */
contract VerifyDocument is Script {
    // Current AffixFactory address
    address constant AFFIX_FACTORY_ADDRESS = 0xc81e0B078De7d58449454b18115616a6a6365A1C;

    function run() public view {
        uint256 chainId = block.chainid;
        console2.log("Verifying document on chain ID:", chainId);

        // Document details from environment
        string memory documentCid = vm.envString("DOCUMENT_CID");
        address registryAddress = vm.envAddress("REGISTRY_ADDRESS");

        require(bytes(documentCid).length > 0, "DOCUMENT_CID environment variable required");
        require(registryAddress != address(0), "REGISTRY_ADDRESS environment variable required");

        AffixFactory factory = AffixFactory(AFFIX_FACTORY_ADDRESS);

        console2.log("Using AffixFactory at:", AFFIX_FACTORY_ADDRESS);
        console2.log("Registry address:", registryAddress);
        console2.log("Document CID to verify:", documentCid);

        // Verify the registry is registered with the factory
        require(factory.isEntityRegistered(registryAddress), "Registry not registered with factory");

        // Get registry details
        AffixRegistry registry = AffixRegistry(registryAddress);

        console2.log("Entity name:", registry.entityName());
        console2.log("Entity URL:", registry.entityUrl());
        console2.log("Registry admin:", registry.admin());

        // Verify the document
        (bool exists, uint256 timestamp, string memory entityName, string memory entityUrl) =
            registry.verifyDocument(documentCid);

        console2.log("\n=== Document Verification Results ===");
        console2.log("Document exists:", exists);

        if (exists) {
            console2.log("Issued timestamp:", timestamp);
            console2.log("Issuing entity:", entityName);
            console2.log("Entity URL:", entityUrl);
            console2.log("Human readable date:", timestampToDate(timestamp));

            // Get full document details
            (
                ,
                ,
                ,
                ,
                // bool existsDetails - not needed
                // uint256 timestampDetails - not needed
                // string memory entityNameDetails - not needed
                // string memory entityUrlDetails - not needed
                string memory metadata,
                address issuedBy
            ) = registry.getDocumentDetails(documentCid);

            console2.log("\n=== Additional Document Details ===");
            console2.log("Metadata:", metadata);
            console2.log("Issued by address:", issuedBy);
            console2.log("Registry contract:", registryAddress);

            // Check if issuer was admin or agent
            if (issuedBy == registry.admin()) console2.log("Issued by: Entity Admin");
            else if (registry.isAgent(issuedBy)) console2.log("Issued by: Authorized Agent");
            else console2.log("Issued by: Unknown (possibly revoked agent)");

            console2.log("\n Document is VALID and VERIFIED");
            console2.log("Verification URL:", entityUrl);
        } else {
            console2.log("\n Document NOT FOUND or INVALID");
            console2.log("This document was not issued by", entityName);
            console2.log("Entity URL:", entityUrl);
        }
    }

    function timestampToDate(uint256 timestamp) internal pure returns (string memory) {
        // Simple timestamp to human readable conversion
        // This is a basic implementation - in practice you might want more sophisticated date formatting
        return string(abi.encodePacked("Unix timestamp: ", vm.toString(timestamp)));
    }
}

// Example usage:
// DOCUMENT_CID="QmExampleDocumentHash123" REGISTRY_ADDRESS="0x..." forge script script/VerifyDocument.s.sol --rpc-url
// localhost
