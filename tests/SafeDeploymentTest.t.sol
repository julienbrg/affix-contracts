// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { Test, console } from "forge-std/src/Test.sol";
import { VeridocsFactory } from "../src/VeridocsFactory.sol";

/**
 * @title SafeDeploymentTest
 * @notice Tests Safe Singleton Factory deployment pattern for VeridocsFactory
 * @dev Verifies deterministic deployment addresses across different chains and deployers
 */
contract SafeDeploymentTest is Test {
    // Safe Singleton Factory address (same on all EVM chains)
    address public constant SAFE_SINGLETON_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;

    // Salt for CREATE2 deployment
    bytes32 public constant SALT = keccak256(bytes("VERIDOCS_DOCUMENT_FACTORY_V1"));

    // Test addresses
    address public constant DEPLOYER1 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address public constant DEPLOYER2 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // Chain IDs for testing
    uint256 public constant ETHEREUM_CHAIN_ID = 1;
    uint256 public constant POLYGON_CHAIN_ID = 137;
    uint256 public constant OPTIMISM_CHAIN_ID = 10;

    // Mock Safe Singleton Factory for testing
    MockSafeSingletonFactory public mockFactory;

    function setUp() public {
        // Deploy mock Safe Singleton Factory
        mockFactory = new MockSafeSingletonFactory();
        console.log("Mock Safe Singleton Factory deployed at:", address(mockFactory));
    }

    function testCalculateExpectedAddress() public view {
        bytes memory creationCode = type(VeridocsFactory).creationCode;
        bytes32 bytecodeHash = keccak256(creationCode);

        address expectedAddress = calculateCreate2Address(address(mockFactory), SALT, bytecodeHash);
        console.log("Expected VeridocsFactory address:", expectedAddress);

        // Verify the address calculation is deterministic
        address expectedAddress2 = calculateCreate2Address(address(mockFactory), SALT, bytecodeHash);
        assertEq(expectedAddress, expectedAddress2, "Address calculation should be deterministic");
    }

    function testDeployWithMockFactory() public {
        bytes memory creationCode = type(VeridocsFactory).creationCode;
        bytes32 bytecodeHash = keccak256(creationCode);
        address expectedAddress = calculateCreate2Address(address(mockFactory), SALT, bytecodeHash);

        vm.startPrank(DEPLOYER1);

        // Deploy using mock factory
        (bool success, bytes memory returnData) = address(mockFactory).call(abi.encodePacked(SALT, creationCode));

        require(success, "Deployment failed");
        address deployedAddress = abi.decode(returnData, (address));

        vm.stopPrank();

        console.log("Deployed VeridocsFactory at:", deployedAddress);
        assertEq(deployedAddress, expectedAddress, "Deployed address should match expected");

        // Verify the contract is working
        VeridocsFactory factory = VeridocsFactory(deployedAddress);
        assertEq(factory.getInstitutionCount(), 0, "Factory should start with 0 institutions");
    }

    function testSameAddressAcrossChains() public {
        bytes memory creationCode = type(VeridocsFactory).creationCode;
        bytes32 bytecodeHash = keccak256(creationCode);

        // All deployments should use the same mock factory address for consistent CREATE2 calculation
        address factoryAddr = address(mockFactory);
        address expectedAddress = calculateCreate2Address(factoryAddr, SALT, bytecodeHash);

        // Deploy on "Ethereum"
        vm.chainId(ETHEREUM_CHAIN_ID);
        address ethAddress = deployVeridocsFactory(DEPLOYER1);

        // Deploy on "Polygon" (simulate different chain but same factory)
        vm.chainId(POLYGON_CHAIN_ID);
        address polygonAddress = deployVeridocsFactory(DEPLOYER2); // Different deployer

        // Deploy on "Optimism"
        vm.chainId(OPTIMISM_CHAIN_ID);
        address optimismAddress = deployVeridocsFactory(DEPLOYER1);

        // All addresses should be the same as expected
        assertEq(ethAddress, expectedAddress, "Ethereum address should match expected");
        assertEq(polygonAddress, expectedAddress, "Polygon address should match expected");
        assertEq(optimismAddress, expectedAddress, "Optimism address should match expected");

        console.log("Verified: Same address across all chains:", expectedAddress);
        console.log("Chain IDs tested:", ETHEREUM_CHAIN_ID, POLYGON_CHAIN_ID, OPTIMISM_CHAIN_ID);
    }

    function testDifferentDeployersSameAddress() public {
        bytes memory creationCode = type(VeridocsFactory).creationCode;
        bytes32 bytecodeHash = keccak256(creationCode);
        address expectedAddress = calculateCreate2Address(address(mockFactory), SALT, bytecodeHash);

        // DEPLOYER1 deploys
        address deployer1Deployment = deployVeridocsFactory(DEPLOYER1);

        // DEPLOYER2 deploys (using same factory instance)
        address deployer2Deployment = deployVeridocsFactory(DEPLOYER2);

        // Both should match the expected address
        assertEq(deployer1Deployment, expectedAddress, "DEPLOYER1 deployment should match expected");
        assertEq(deployer2Deployment, expectedAddress, "DEPLOYER2 deployment should match expected");

        console.log("Verified: Same address regardless of deployer");
        console.log("Expected address:", expectedAddress);
        console.log("DEPLOYER1 deployment:", deployer1Deployment);
        console.log("DEPLOYER2 deployment:", deployer2Deployment);
    }

    function testCannotDeployTwice() public {
        // First deployment
        address firstDeployment = deployVeridocsFactory(DEPLOYER1);

        // Second deployment should return same address (not fail, but not create new contract)
        address secondDeployment = deployVeridocsFactory(DEPLOYER2);

        // Should be same address
        assertEq(firstDeployment, secondDeployment, "Should return same address when already deployed");

        console.log("Verified: Returns same address when contract already exists");
        console.log("First deployment:", firstDeployment);
        console.log("Second deployment:", secondDeployment);
    }

    function testDeploymentGasCost() public {
        bytes memory creationCode = type(VeridocsFactory).creationCode;

        vm.startPrank(DEPLOYER1);
        uint256 gasBefore = gasleft();

        (bool success,) = address(mockFactory).call(abi.encodePacked(SALT, creationCode));
        require(success, "Deployment failed");

        uint256 gasUsed = gasBefore - gasleft();
        vm.stopPrank();

        console.log("Gas used for deployment:", gasUsed);

        // Gas should be reasonable (increased limit due to added complexity with agent system)
        assertLt(gasUsed, 2_500_000, "Deployment should use reasonable gas");
    }

    function testFactoryFunctionality() public {
        // Deploy factory
        address factoryAddress = deployVeridocsFactory(DEPLOYER1);
        VeridocsFactory factory = VeridocsFactory(factoryAddress);

        // Test basic functionality
        vm.prank(DEPLOYER1);
        factory.registerInstitution("Test University");

        assertTrue(factory.isInstitutionRegistered(DEPLOYER1), "Institution should be registered");
        assertEq(factory.getInstitutionCount(), 1, "Should have 1 institution");

        address registryAddress = factory.getInstitutionRegistry(DEPLOYER1);
        assertTrue(registryAddress != address(0), "Registry address should not be zero");

        console.log("Verified: Deployed factory works correctly");
        console.log("Factory address:", factoryAddress);
        console.log("Registry address:", registryAddress);
    }

    // Helper function to deploy VeridocsFactory using mock Safe Singleton Factory
    function deployVeridocsFactory(address deployer) internal returns (address) {
        bytes memory creationCode = type(VeridocsFactory).creationCode;

        vm.prank(deployer);
        (bool success, bytes memory returnData) = address(mockFactory).call(abi.encodePacked(SALT, creationCode));

        require(success, "Deployment failed");
        return abi.decode(returnData, (address));
    }

    function calculateCreate2Address(
        address deployer,
        bytes32 salt,
        bytes32 bytecodeHash
    )
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)))));
    }
}

/**
 * @title MockSafeSingletonFactory
 * @notice Mock implementation of Safe Singleton Factory for testing
 * @dev Simulates CREATE2 deployment functionality
 */
contract MockSafeSingletonFactory {
    mapping(bytes32 => address) public deployedContracts;

    // Add receive function to handle plain ether transfers
    receive() external payable { }

    /**
     * @notice Simulates CREATE2 deployment
     * @dev Extracts salt and creation code from calldata and deploys with CREATE2
     */
    fallback() external payable {
        // Extract salt and creation code from calldata
        bytes32 salt;
        bytes memory creationCode;

        assembly {
            salt := calldataload(0)

            // Get creation code length and copy it
            let codeLength := sub(calldatasize(), 32) // 32 bytes for salt
            creationCode := mload(0x40)
            mstore(0x40, add(creationCode, add(codeLength, 32)))
            mstore(creationCode, codeLength)
            calldatacopy(add(creationCode, 32), 32, codeLength)
        }

        // Check if already deployed
        bytes32 deploymentKey = keccak256(abi.encodePacked(salt, keccak256(creationCode)));
        address existingDeployment = deployedContracts[deploymentKey];

        if (existingDeployment != address(0)) {
            // Already deployed, return existing address
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, existingDeployment)
                return(ptr, 32)
            }
        }

        // Deploy with CREATE2
        address deployedAddress;
        assembly {
            deployedAddress := create2(0, add(creationCode, 32), mload(creationCode), salt)
            if iszero(deployedAddress) { revert(0, 0) }
        }

        // Store deployment
        deployedContracts[deploymentKey] = deployedAddress;

        // Return the deployed address
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, deployedAddress)
            return(ptr, 32)
        }
    }
}
