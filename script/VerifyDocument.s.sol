// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { console2 } from "forge-std/src/console2.sol";
import { Script } from "forge-std/src/Script.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title VerifyDocument
 * @notice Script to verify a document using an institution's VeridocsRegistry
 * @dev Anyone can verify documents - no authentication required
 */
contract VerifyDocument is Script {
    // Calculate the expected VeridocsFactory address (same across all chains)
    address constant SAFE_SINGLETON_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;
    bytes32 constant SALT = keccak256(bytes("VERIDOCS_DOCUMENT_FACTORY_V1"));

    function run() public view {
        uint256 chainId = block.chainid;
        console2.log("Verifying document on chain ID:", chainId);

        // Calculate the expected factory address
        bytes memory factoryCreationCode = type(VeridocsFactory).creationCode;
        bytes32 factoryBytecodeHash = keccak256(factoryCreationCode);
        address expectedFactoryAddress = address(
            uint160(
                uint256(keccak256(abi.encodePacked(bytes1(0xff), SAFE_SINGLETON_FACTORY, SALT, factoryBytecodeHash)))
            )
        );

        // Document details from environment
        string memory documentCid = vm.envString("DOCUMENT_CID");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");

        require(bytes(documentCid).length > 0, "DOCUMENT_CID environment variable required");
        require(adminAddress != address(0), "ADMIN_ADDRESS environment variable required");

        VeridocsFactory factory = VeridocsFactory(expectedFactoryAddress);

        console2.log("Using VeridocsFactory at:", expectedFactoryAddress);
        console2.log("Admin address:", adminAddress);
        console2.log("Document CID to verify:", documentCid);

        // Check if admin is registered
        require(factory.isInstitutionRegistered(adminAddress), "Admin not registered");

        // Get the registry address
        address registryAddress = factory.getInstitutionRegistry(adminAddress);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        console2.log("Using registry at:", registryAddress);
        console2.log("Institution name:", registry.institutionName());

        // Verify the document
        (bool exists, uint256 timestamp, string memory institutionName) = registry.verifyDocument(documentCid);

        console2.log("\n=== Document Verification Results ===");
        console2.log("Document exists:", exists);

        if (exists) {
            console2.log("Issued timestamp:", timestamp);
            console2.log("Issuing institution:", institutionName);
            console2.log("Human readable date:", timestampToDate(timestamp));

            // Get full document details
            (
                bool existsDetails,
                uint256 timestampDetails,
                string memory institutionNameDetails,
                string memory metadata,
                address issuedBy
            ) = registry.getDocumentDetails(documentCid);

            console2.log("\n=== Additional Document Details ===");
            console2.log("Metadata:", metadata);
            console2.log("Issued by address:", issuedBy);
            console2.log("Registry contract:", registryAddress);

            // Check if issuer was admin or agent
            if (issuedBy == registry.admin()) console2.log("Issued by: Institution Admin");
            else if (registry.isAgent(issuedBy)) console2.log("Issued by: Authorized Agent");
            else console2.log("Issued by: Unknown (possibly revoked agent)");

            console2.log("\n Document is VALID and VERIFIED");
        } else {
            console2.log("\n Document NOT FOUND or INVALID");
            console2.log("This document was not issued by", institutionName);
        }
    }

    function timestampToDate(uint256 timestamp) internal pure returns (string memory) {
        // Simple timestamp to human readable conversion
        // This is a basic implementation - in practice you might want more sophisticated date formatting
        return string(abi.encodePacked("Unix timestamp: ", vm.toString(timestamp)));
    }
}
