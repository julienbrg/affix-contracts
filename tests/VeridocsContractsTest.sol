// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { Test, console } from "forge-std/src/Test.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title VeridocsContractsTest
 * @notice Comprehensive tests for VeridocsFactory and VeridocsRegistry contracts with admin/agent system
 * @dev Tests deployment, registration, agent management, document issuance, and verification
 */
contract VeridocsContractsTest is Test {
    VeridocsFactory public factory;

    // Test addresses
    address public constant ADMIN = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant AGENT1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public constant AGENT2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address public constant OTHER_ADMIN = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address public constant VERIFIER = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    address public constant UNAUTHORIZED = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;

    // Test data
    string constant INSTITUTION_NAME = "Test University";
    string constant DOCUMENT_CID = "QmTestDocumentCid123";
    string constant DOCUMENT_METADATA = "Bachelor of Science in Computer Science";

    // Events to test
    event InstitutionRegistered(address indexed admin, address indexed contractAddress, string institutionName);
    event DocumentIssued(string indexed cid, uint256 timestamp, string metadata, address indexed issuedBy);
    event AgentAdded(address indexed agent, address indexed addedBy);
    event AgentRevoked(address indexed agent, address indexed revokedBy);

    function setUp() public {
        // Deploy VeridocsFactory
        factory = new VeridocsFactory();
        console.log("VeridocsFactory deployed at:", address(factory));
    }

    function testDeployment() public view {
        // Verify factory is deployed correctly
        assertEq(factory.getInstitutionCount(), 0);
        assertFalse(factory.isInstitutionRegistered(ADMIN));
    }

    function testRegisterInstitution() public {
        vm.startPrank(ADMIN);

        // Expect the InstitutionRegistered event
        vm.expectEmit(true, false, false, true);
        emit InstitutionRegistered(ADMIN, address(0), INSTITUTION_NAME); // address(0) as placeholder

        factory.registerInstitution(INSTITUTION_NAME);

        vm.stopPrank();

        // Verify registration
        assertTrue(factory.isInstitutionRegistered(ADMIN));
        assertEq(factory.getInstitutionCount(), 1);
        assertEq(factory.getInstitutionByIndex(0), ADMIN);

        // Get registry address
        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        assertTrue(registryAddress != address(0));

        // Verify registry details
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);
        assertEq(registry.admin(), ADMIN);
        assertEq(registry.institutionName(), INSTITUTION_NAME);
        assertTrue(registry.isValidRegistry());
    }

    function testCannotRegisterTwice() public {
        vm.startPrank(ADMIN);

        // First registration should succeed
        factory.registerInstitution(INSTITUTION_NAME);

        // Second registration should fail
        vm.expectRevert("Admin already registered");
        factory.registerInstitution("Another Name");

        vm.stopPrank();
    }

    function testCannotRegisterEmptyName() public {
        vm.startPrank(ADMIN);

        vm.expectRevert("Institution name cannot be empty");
        factory.registerInstitution("");

        vm.stopPrank();
    }

    function testAddAgent() public {
        // Register institution first
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);

        // Expect the AgentAdded event
        vm.expectEmit(true, true, false, false);
        emit AgentAdded(AGENT1, ADMIN);

        registry.addAgent(AGENT1);

        vm.stopPrank();

        // Verify agent was added
        assertTrue(registry.isAgent(AGENT1));
        assertTrue(registry.canIssueDocuments(AGENT1));
        assertEq(registry.getAgentCount(), 1);

        address[] memory activeAgents = registry.getActiveAgents();
        assertEq(activeAgents.length, 1);
        assertEq(activeAgents[0], AGENT1);
    }

    function testAddMultipleAgents() public {
        // Register institution first
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);

        registry.addAgent(AGENT1);
        registry.addAgent(AGENT2);

        vm.stopPrank();

        // Verify both agents were added
        assertTrue(registry.isAgent(AGENT1));
        assertTrue(registry.isAgent(AGENT2));
        assertEq(registry.getAgentCount(), 2);

        address[] memory activeAgents = registry.getActiveAgents();
        assertEq(activeAgents.length, 2);
        // Check that both agents are in the array (order might vary)
        bool found1 = false;
        bool found2 = false;
        for (uint256 i = 0; i < activeAgents.length; i++) {
            if (activeAgents[i] == AGENT1) found1 = true;
            if (activeAgents[i] == AGENT2) found2 = true;
        }
        assertTrue(found1 && found2);
    }

    function testOnlyAdminCanAddAgent() public {
        // Register institution first
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // AGENT1 tries to add AGENT2 (should fail)
        vm.prank(AGENT1);
        vm.expectRevert("Only admin can call this function");
        registry.addAgent(AGENT2);
    }

    function testCannotAddInvalidAgent() public {
        // Register institution first
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);

        // Cannot add zero address
        vm.expectRevert("Invalid agent address");
        registry.addAgent(address(0));

        // Cannot add admin as agent
        vm.expectRevert("Admin cannot be an agent");
        registry.addAgent(ADMIN);

        vm.stopPrank();
    }

    function testCannotAddAgentTwice() public {
        // Register institution first
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);

        // First addition should succeed
        registry.addAgent(AGENT1);

        // Second addition should fail
        vm.expectRevert("Agent already exists");
        registry.addAgent(AGENT1);

        vm.stopPrank();
    }

    function testRevokeAgent() public {
        // Register institution and add agent
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);

        registry.addAgent(AGENT1);
        registry.addAgent(AGENT2);

        // Verify agents are active
        assertTrue(registry.isAgent(AGENT1));
        assertTrue(registry.isAgent(AGENT2));
        assertEq(registry.getAgentCount(), 2);

        // Expect the AgentRevoked event
        vm.expectEmit(true, true, false, false);
        emit AgentRevoked(AGENT1, ADMIN);

        registry.revokeAgent(AGENT1);

        vm.stopPrank();

        // Verify AGENT1 was revoked but AGENT2 remains
        assertFalse(registry.isAgent(AGENT1));
        assertTrue(registry.isAgent(AGENT2));
        assertEq(registry.getAgentCount(), 1);

        address[] memory activeAgents = registry.getActiveAgents();
        assertEq(activeAgents.length, 1);
        assertEq(activeAgents[0], AGENT2);
    }

    function testCannotRevokeNonexistentAgent() public {
        // Register institution first
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.prank(ADMIN);
        vm.expectRevert("Agent does not exist");
        registry.revokeAgent(AGENT1);
    }

    function testOnlyAdminCanRevokeAgent() public {
        // Register institution and add agent
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.prank(ADMIN);
        registry.addAgent(AGENT1);

        // AGENT1 tries to revoke themselves (should fail)
        vm.prank(AGENT1);
        vm.expectRevert("Only admin can call this function");
        registry.revokeAgent(AGENT1);
    }

    function testAdminCanIssueDocument() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);

        // Expect the DocumentIssued event
        vm.expectEmit(true, false, false, true);
        emit DocumentIssued(DOCUMENT_CID, block.timestamp, "", ADMIN);

        registry.issueDocument(DOCUMENT_CID);

        vm.stopPrank();

        // Verify document
        (bool exists, uint256 timestamp, string memory institutionName) = registry.verifyDocument(DOCUMENT_CID);
        assertTrue(exists);
        assertEq(timestamp, block.timestamp);
        assertEq(institutionName, INSTITUTION_NAME);
        assertEq(registry.getDocumentCount(), 1);

        // Check document details
        (
            bool existsDetails,
            uint256 timestampDetails,
            string memory institutionNameDetails,
            string memory metadata,
            address issuedBy
        ) = registry.getDocumentDetails(DOCUMENT_CID);

        assertTrue(existsDetails);
        assertEq(timestampDetails, timestamp);
        assertEq(institutionNameDetails, INSTITUTION_NAME);
        assertEq(metadata, "");
        assertEq(issuedBy, ADMIN);
    }

    function testAgentCanIssueDocument() public {
        // Register institution and add agent
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.prank(ADMIN);
        registry.addAgent(AGENT1);

        vm.startPrank(AGENT1);

        // Expect the DocumentIssued event
        vm.expectEmit(true, false, false, true);
        emit DocumentIssued(DOCUMENT_CID, block.timestamp, DOCUMENT_METADATA, AGENT1);

        registry.issueDocumentWithMetadata(DOCUMENT_CID, DOCUMENT_METADATA);

        vm.stopPrank();

        // Verify document
        (bool exists, uint256 timestamp, string memory institutionName) = registry.verifyDocument(DOCUMENT_CID);
        assertTrue(exists);
        assertEq(timestamp, block.timestamp);
        assertEq(institutionName, INSTITUTION_NAME);

        // Check document details
        (
            bool existsDetails,
            uint256 timestampDetails,
            string memory institutionNameDetails,
            string memory metadata,
            address issuedBy
        ) = registry.getDocumentDetails(DOCUMENT_CID);

        assertTrue(existsDetails);
        assertEq(timestampDetails, timestamp);
        assertEq(institutionNameDetails, INSTITUTION_NAME);
        assertEq(metadata, DOCUMENT_METADATA);
        assertEq(issuedBy, AGENT1);
    }

    function testUnauthorizedCannotIssueDocument() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Unauthorized user tries to issue document
        vm.prank(UNAUTHORIZED);
        vm.expectRevert("Only admin or authorized agent can call this function");
        registry.issueDocument(DOCUMENT_CID);
    }

    function testRevokedAgentCannotIssueDocument() public {
        // Register institution and add agent
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);
        registry.addAgent(AGENT1);

        // Agent issues a document successfully
        vm.stopPrank();
        vm.prank(AGENT1);
        registry.issueDocument("QmFirstDoc");

        // Admin revokes the agent
        vm.prank(ADMIN);
        registry.revokeAgent(AGENT1);

        // Revoked agent tries to issue another document (should fail)
        vm.prank(AGENT1);
        vm.expectRevert("Only admin or authorized agent can call this function");
        registry.issueDocument(DOCUMENT_CID);
    }

    function testCannotIssueDocumentTwice() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.startPrank(ADMIN);

        // First issuance should succeed
        registry.issueDocument(DOCUMENT_CID);

        // Second issuance should fail
        vm.expectRevert("Document already exists");
        registry.issueDocument(DOCUMENT_CID);

        vm.stopPrank();
    }

    function testCannotIssueEmptyIPFSCid() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.prank(ADMIN);
        vm.expectRevert("IPFS CID cannot be empty");
        registry.issueDocument("");
    }

    function testUpdateInstitutionNameFactoryMethod() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        string memory newName = "Updated University Name";

        // Update through factory should now revert with explanation
        vm.prank(ADMIN);
        vm.expectRevert("Use registry.updateInstitutionName() directly");
        factory.updateInstitutionName(newName);
    }

    function testUpdateInstitutionNameDirectly() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        string memory newName = "Updated University Name";

        // Update directly through the registry
        vm.prank(ADMIN);
        registry.updateInstitutionName(newName);

        // Verify name was updated
        assertEq(registry.institutionName(), newName);

        // Test that non-admin cannot update
        vm.prank(AGENT1);
        vm.expectRevert("Only admin can call this function");
        registry.updateInstitutionName("Hacker University");
    }

    function testCannotUpdateInstitutionNameEmpty() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        vm.prank(ADMIN);
        vm.expectRevert("Institution name cannot be empty");
        registry.updateInstitutionName("");
    }

    function testMultipleInstitutions() public {
        // Register ADMIN
        vm.prank(ADMIN);
        factory.registerInstitution("University A");

        // Register OTHER_ADMIN
        vm.prank(OTHER_ADMIN);
        factory.registerInstitution("University B");

        // Verify both are registered
        assertTrue(factory.isInstitutionRegistered(ADMIN));
        assertTrue(factory.isInstitutionRegistered(OTHER_ADMIN));
        assertEq(factory.getInstitutionCount(), 2);

        // Verify different registry addresses
        address adminRegistry = factory.getInstitutionRegistry(ADMIN);
        address otherAdminRegistry = factory.getInstitutionRegistry(OTHER_ADMIN);
        assertTrue(adminRegistry != otherAdminRegistry);
    }

    function testGetAllInstitutions() public {
        // Register multiple institutions
        vm.prank(ADMIN);
        factory.registerInstitution("University A");

        vm.prank(OTHER_ADMIN);
        factory.registerInstitution("University B");

        vm.prank(AGENT1);
        factory.registerInstitution("University C");

        // Get all institutions
        address[] memory institutions = factory.getAllInstitutions();
        assertEq(institutions.length, 3);
        assertEq(institutions[0], ADMIN);
        assertEq(institutions[1], OTHER_ADMIN);
        assertEq(institutions[2], AGENT1);
    }

    function testGetInstitutionDetails() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        // Get details
        (address registryAddress, string memory institutionName, bool isRegistered) =
            factory.getInstitutionDetails(ADMIN);

        assertTrue(isRegistered);
        assertEq(institutionName, INSTITUTION_NAME);
        assertTrue(registryAddress != address(0));

        // Test for unregistered admin
        (address unregRegistry, string memory unregName, bool unregIsRegistered) =
            factory.getInstitutionDetails(OTHER_ADMIN);

        assertFalse(unregIsRegistered);
        assertEq(unregRegistry, address(0));
        assertEq(bytes(unregName).length, 0);
    }

    function testDocumentEnumeration() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Issue multiple documents
        vm.startPrank(ADMIN);
        registry.issueDocument("QmDoc1");
        registry.issueDocument("QmDoc2");
        registry.issueDocument("QmDoc3");
        vm.stopPrank();

        // Test enumeration
        assertEq(registry.getDocumentCount(), 3);
        assertEq(registry.getDocumentCidByIndex(0), "QmDoc1");
        assertEq(registry.getDocumentCidByIndex(1), "QmDoc2");
        assertEq(registry.getDocumentCidByIndex(2), "QmDoc3");

        // Test getting all CIDs
        string[] memory allCids = registry.getAllDocumentCids();
        assertEq(allCids.length, 3);
        assertEq(allCids[0], "QmDoc1");
        assertEq(allCids[1], "QmDoc2");
        assertEq(allCids[2], "QmDoc3");
    }

    function testRegistryInfo() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Add agents and issue documents
        vm.startPrank(ADMIN);
        registry.addAgent(AGENT1);
        registry.addAgent(AGENT2);
        registry.issueDocument("QmDoc1");
        registry.issueDocument("QmDoc2");
        vm.stopPrank();

        // Test registry info
        (address admin, string memory institutionName, uint256 documentCount, uint256 agentCount) =
            registry.getRegistryInfo();

        assertEq(admin, ADMIN);
        assertEq(institutionName, INSTITUTION_NAME);
        assertEq(documentCount, 2);
        assertEq(agentCount, 2);
    }

    function testVerificationWorkflow() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Add agent
        vm.prank(ADMIN);
        registry.addAgent(AGENT1);

        // AGENT1 issues document
        vm.prank(AGENT1);
        registry.issueDocumentWithMetadata(DOCUMENT_CID, DOCUMENT_METADATA);

        // VERIFIER verifies the document
        vm.prank(VERIFIER);
        (bool exists, uint256 timestamp, string memory institutionName) = registry.verifyDocument(DOCUMENT_CID);

        assertTrue(exists);
        assertEq(institutionName, INSTITUTION_NAME);
        assertGt(timestamp, 0);

        // VERIFIER gets full document details
        vm.prank(VERIFIER);
        (
            bool existsDetails,
            uint256 timestampDetails,
            string memory institutionNameDetails,
            string memory metadata,
            address issuedBy
        ) = registry.getDocumentDetails(DOCUMENT_CID);

        assertTrue(existsDetails);
        assertEq(timestampDetails, timestamp);
        assertEq(institutionNameDetails, INSTITUTION_NAME);
        assertEq(metadata, DOCUMENT_METADATA);
        assertEq(issuedBy, AGENT1);
    }

    function testAgentManagementIsolation() public {
        // ADMIN registers their institution
        vm.prank(ADMIN);
        factory.registerInstitution("Admin University");

        // OTHER_ADMIN registers their institution
        vm.prank(OTHER_ADMIN);
        factory.registerInstitution("Other Admin University");

        address adminRegistry = factory.getInstitutionRegistry(ADMIN);
        address otherAdminRegistry = factory.getInstitutionRegistry(OTHER_ADMIN);

        VeridocsRegistry adminRegistryContract = VeridocsRegistry(adminRegistry);
        VeridocsRegistry otherAdminRegistryContract = VeridocsRegistry(otherAdminRegistry);

        // ADMIN adds AGENT1 to their registry
        vm.prank(ADMIN);
        adminRegistryContract.addAgent(AGENT1);

        // OTHER_ADMIN cannot add agents to ADMIN's registry
        vm.prank(OTHER_ADMIN);
        vm.expectRevert("Only admin can call this function");
        adminRegistryContract.addAgent(AGENT2);

        // OTHER_ADMIN can add agents to their own registry
        vm.prank(OTHER_ADMIN);
        otherAdminRegistryContract.addAgent(AGENT2);

        // Verify separation
        assertTrue(adminRegistryContract.isAgent(AGENT1));
        assertFalse(adminRegistryContract.isAgent(AGENT2));
        assertFalse(otherAdminRegistryContract.isAgent(AGENT1));
        assertTrue(otherAdminRegistryContract.isAgent(AGENT2));
    }

    function testDocumentIssueIsolation() public {
        // ADMIN registers their institution
        vm.prank(ADMIN);
        factory.registerInstitution("Admin University");

        // OTHER_ADMIN registers their institution
        vm.prank(OTHER_ADMIN);
        factory.registerInstitution("Other Admin University");

        address adminRegistry = factory.getInstitutionRegistry(ADMIN);
        address otherAdminRegistry = factory.getInstitutionRegistry(OTHER_ADMIN);

        VeridocsRegistry adminRegistryContract = VeridocsRegistry(adminRegistry);
        VeridocsRegistry otherAdminRegistryContract = VeridocsRegistry(otherAdminRegistry);

        // ADMIN adds AGENT1, OTHER_ADMIN adds AGENT2
        vm.prank(ADMIN);
        adminRegistryContract.addAgent(AGENT1);

        vm.prank(OTHER_ADMIN);
        otherAdminRegistryContract.addAgent(AGENT2);

        // AGENT1 can issue document on ADMIN's registry
        vm.prank(AGENT1);
        adminRegistryContract.issueDocument("QmAdminDoc");

        // AGENT1 cannot issue document on OTHER_ADMIN's registry
        vm.prank(AGENT1);
        vm.expectRevert("Only admin or authorized agent can call this function");
        otherAdminRegistryContract.issueDocument("QmHackerDoc");

        // AGENT2 can issue on OTHER_ADMIN's registry
        vm.prank(AGENT2);
        otherAdminRegistryContract.issueDocument("QmOtherAdminDoc");

        // Verify separation
        (bool adminDocExists,,) = adminRegistryContract.verifyDocument("QmAdminDoc");
        (bool otherAdminDocExists,,) = otherAdminRegistryContract.verifyDocument("QmOtherAdminDoc");
        (bool crossDocExists,,) = adminRegistryContract.verifyDocument("QmOtherAdminDoc");

        assertTrue(adminDocExists);
        assertTrue(otherAdminDocExists);
        assertFalse(crossDocExists); // OTHER_ADMIN's doc doesn't exist in ADMIN's registry
    }

    function testCanIssueDocumentsFunction() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Admin can issue documents
        assertTrue(registry.canIssueDocuments(ADMIN));

        // Unauthorized user cannot issue documents
        assertFalse(registry.canIssueDocuments(UNAUTHORIZED));

        // Add agent
        vm.prank(ADMIN);
        registry.addAgent(AGENT1);

        // Agent can now issue documents
        assertTrue(registry.canIssueDocuments(AGENT1));

        // Revoke agent
        vm.prank(ADMIN);
        registry.revokeAgent(AGENT1);

        // Agent can no longer issue documents
        assertFalse(registry.canIssueDocuments(AGENT1));
    }

    function testRegistryValidation() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Registry should be valid
        assertTrue(registry.isValidRegistry());

        // Check all components
        assertEq(registry.admin(), ADMIN);
        assertEq(registry.institutionName(), INSTITUTION_NAME);
        assertEq(registry.getDocumentCount(), 0);
        assertEq(registry.getAgentCount(), 0);
    }

    function testIndexOutOfBounds() public {
        // Register institution
        vm.prank(ADMIN);
        factory.registerInstitution(INSTITUTION_NAME);

        address registryAddress = factory.getInstitutionRegistry(ADMIN);
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Test document index out of bounds
        vm.expectRevert("Index out of bounds");
        registry.getDocumentCidByIndex(0);

        // Test factory index out of bounds
        vm.expectRevert("Index out of bounds");
        factory.getInstitutionByIndex(1);
    }
}
