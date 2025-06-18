// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { Test } from "forge-std/src/Test.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";
import { VeridocsRegistry } from "../src/VeridocsRegistry.sol";

/**
 * @title VeridocsContractsTest
 * @notice Tests for simplified VeridocsFactory (institution-centric approach)
 */
contract VeridocsContractsTest is Test {
    VeridocsFactory public factory;

    // Test addresses
    address public constant FACTORY_OWNER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant ADMIN1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address public constant ADMIN2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address public constant AGENT1 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address public constant UNAUTHORIZED = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;

    // Test data
    string constant INSTITUTION_NAME1 = "Test University";
    string constant INSTITUTION_NAME2 = "Second University";
    string constant DOCUMENT_CID = "QmTestDocumentCid123";

    // Events to test
    event InstitutionRegistered(address indexed admin, address indexed contractAddress, string institutionName);

    function setUp() public {
        // Deploy factory with FACTORY_OWNER as the owner
        vm.prank(FACTORY_OWNER);
        factory = new VeridocsFactory();

        // Verify owner is set correctly
        assertEq(factory.owner(), FACTORY_OWNER, "Factory owner should be set correctly");
    }

    function testFactoryOwnership() public view {
        // Verify initial ownership
        assertEq(factory.owner(), FACTORY_OWNER, "Factory owner should be FACTORY_OWNER");
    }

    function testOnlyOwnerCanRegisterInstitution() public {
        // Factory owner can register institution
        vm.prank(FACTORY_OWNER);
        address registryAddress = factory.registerInstitution(ADMIN1, INSTITUTION_NAME1);

        assertTrue(factory.isInstitutionRegistered(registryAddress), "Institution should be registered");

        // Non-owner cannot register institution
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", UNAUTHORIZED));
        vm.prank(UNAUTHORIZED);
        factory.registerInstitution(ADMIN2, INSTITUTION_NAME2);
    }

    function testRegisterInstitutionWithValidAdmin() public {
        // Register institution with specific admin
        vm.prank(FACTORY_OWNER);
        address registryAddress = factory.registerInstitution(ADMIN1, INSTITUTION_NAME1);

        // Verify registration
        assertTrue(factory.isInstitutionRegistered(registryAddress), "Institution should be registered");
        assertEq(factory.getInstitutionCount(), 1, "Should have 1 institution");

        // Get registry and verify admin
        VeridocsRegistry registry = VeridocsRegistry(registryAddress);
        assertEq(registry.admin(), ADMIN1, "Registry admin should be set correctly");
        assertEq(registry.institutionName(), INSTITUTION_NAME1, "Institution name should match");
    }

    function testCannotRegisterWithZeroAddress() public {
        vm.expectRevert("Invalid admin address");
        vm.prank(FACTORY_OWNER);
        factory.registerInstitution(address(0), INSTITUTION_NAME1);
    }

    function testCannotRegisterWithEmptyName() public {
        vm.expectRevert("Institution name cannot be empty");
        vm.prank(FACTORY_OWNER);
        factory.registerInstitution(ADMIN1, "");
    }

    function testMultipleInstitutions() public {
        // Register multiple institutions
        vm.startPrank(FACTORY_OWNER);
        address registry1 = factory.registerInstitution(ADMIN1, INSTITUTION_NAME1);
        address registry2 = factory.registerInstitution(ADMIN2, INSTITUTION_NAME2);
        vm.stopPrank();

        // Test enumeration
        assertEq(factory.getInstitutionCount(), 2, "Should have 2 institutions");

        // Test get by index
        assertEq(factory.getInstitutionByIndex(0), registry1, "First registry should match");
        assertEq(factory.getInstitutionByIndex(1), registry2, "Second registry should match");

        // Test get all institutions
        address[] memory allInstitutions = factory.getAllInstitutions();
        assertEq(allInstitutions.length, 2, "Should return 2 institutions");
        assertEq(allInstitutions[0], registry1, "First institution should match");
        assertEq(allInstitutions[1], registry2, "Second institution should match");

        // Verify both are registered
        assertTrue(factory.isInstitutionRegistered(registry1), "Registry1 should be registered");
        assertTrue(factory.isInstitutionRegistered(registry2), "Registry2 should be registered");
    }

    function testGetInstitutionDetails() public {
        // Register institution
        vm.prank(FACTORY_OWNER);
        address registryAddress = factory.registerInstitution(ADMIN1, INSTITUTION_NAME1);

        // Get details
        (address admin, string memory institutionName, bool isRegistered) = factory.getInstitutionDetails(
            registryAddress
        );

        assertTrue(isRegistered, "Should be registered");
        assertEq(admin, ADMIN1, "Admin should match");
        assertEq(institutionName, INSTITUTION_NAME1, "Institution name should match");

        // Test non-registered registry address
        address fakeRegistry = address(0x1234);
        (address adminFake, string memory instNameFake, bool registeredFake) = factory.getInstitutionDetails(
            fakeRegistry
        );

        assertFalse(registeredFake, "Should not be registered");
        assertEq(adminFake, address(0), "Admin should be zero");
        assertEq(bytes(instNameFake).length, 0, "Institution name should be empty");
    }

    function testFactoryStats() public {
        // Initially empty
        (uint256 totalInstitutions, address owner) = factory.getFactoryStats();
        assertEq(totalInstitutions, 0, "Should start with 0 institutions");
        assertEq(owner, FACTORY_OWNER, "Owner should be FACTORY_OWNER");

        // After registering institutions
        vm.startPrank(FACTORY_OWNER);
        factory.registerInstitution(ADMIN1, INSTITUTION_NAME1);
        factory.registerInstitution(ADMIN2, INSTITUTION_NAME2);
        vm.stopPrank();

        (totalInstitutions, owner) = factory.getFactoryStats();
        assertEq(totalInstitutions, 2, "Should have 2 institutions");
        assertEq(owner, FACTORY_OWNER, "Owner should remain FACTORY_OWNER");
    }

    function testIndexOutOfBounds() public {
        // Test when no institutions are registered
        vm.expectRevert("Index out of bounds");
        factory.getInstitutionByIndex(0);

        // Register one institution
        vm.prank(FACTORY_OWNER);
        factory.registerInstitution(ADMIN1, INSTITUTION_NAME1);

        // Valid index should work
        address registryAddress = factory.getInstitutionByIndex(0);
        assertTrue(registryAddress != address(0), "Should return valid registry address");

        // Invalid index should revert
        vm.expectRevert("Index out of bounds");
        factory.getInstitutionByIndex(1);
    }

    function testRegistryFunctionality() public {
        // Register institution through factory
        vm.prank(FACTORY_OWNER);
        address registryAddress = factory.registerInstitution(ADMIN1, INSTITUTION_NAME1);

        VeridocsRegistry registry = VeridocsRegistry(registryAddress);

        // Admin can add agents
        vm.prank(ADMIN1);
        registry.addAgent(AGENT1);

        assertTrue(registry.isAgent(AGENT1), "Agent should be added");
        assertTrue(registry.canIssueDocuments(AGENT1), "Agent should be able to issue documents");

        // Agent can issue documents
        vm.prank(AGENT1);
        registry.issueDocument(DOCUMENT_CID);

        // Verify document
        (bool exists, uint256 timestamp, string memory institutionName) = registry.verifyDocument(DOCUMENT_CID);
        assertTrue(exists, "Document should exist");
        assertGt(timestamp, 0, "Timestamp should be set");
        assertEq(institutionName, INSTITUTION_NAME1, "Institution name should match");
    }

    function testNonValidRegistryCheck() public view {
        // Create a fake registry address that wasn't deployed by the factory
        address fakeRegistry = address(0x999);

        // Should not be considered registered
        assertFalse(factory.isInstitutionRegistered(fakeRegistry), "Fake registry should not be registered");

        // Getting details should return false for isRegistered
        (address admin, string memory name, bool isRegistered) = factory.getInstitutionDetails(fakeRegistry);
        assertFalse(isRegistered, "Fake registry should not be registered");
        assertEq(admin, address(0), "Admin should be zero for fake registry");
        assertEq(bytes(name).length, 0, "Name should be empty for fake registry");
    }
}
