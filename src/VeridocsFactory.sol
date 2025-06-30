// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { VeridocsRegistry } from "./VeridocsRegistry.sol";

/**
 * @title VeridocsFactory
 * @dev Factory contract for creating and managing VeridocsRegistry contracts for institutions
 * @notice Only the owner can register new institutions
 */
contract VeridocsFactory is Ownable {
    // Array of all deployed registry addresses for enumeration
    address[] public deployedRegistries;

    // Mapping to check if a registry address is valid (deployed by this factory)
    mapping(address => bool) public isValidRegistry;

    // Events
    event InstitutionRegistered(
        address indexed admin, address indexed contractAddress, string institutionName, string url
    );

    /**
     * @dev Constructor - sets the specified address as the owner
     * @param initialOwner The address that will become the owner of this factory
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        require(initialOwner != address(0), "Initial owner cannot be zero address");
    }

    /**
     * @dev Register a new institution and deploy their VeridocsRegistry contract
     * @param admin The address that will be the admin of the new registry
     * @param name The name of the institution
     * @param url The URL associated with the institution (e.g., website, verification portal)
     * @notice Only the factory owner can register new institutions
     * @return registryAddress The address of the newly deployed registry
     */
    function registerInstitution(
        address admin,
        string memory name,
        string memory url
    )
        external
        onlyOwner
        returns (address registryAddress)
    {
        require(admin != address(0), "Invalid admin address");
        require(bytes(name).length > 0, "Institution name cannot be empty");
        require(bytes(url).length > 0, "Institution URL cannot be empty");

        // Deploy new VeridocsRegistry contract
        VeridocsRegistry newRegistry = new VeridocsRegistry(admin, name, url);
        registryAddress = address(newRegistry);

        // Update tracking
        deployedRegistries.push(registryAddress);
        isValidRegistry[registryAddress] = true;

        emit InstitutionRegistered(admin, registryAddress, name, url);
    }

    /**
     * @dev Check if an institution registry is deployed by this factory
     * @param registryAddress The registry address to check
     * @return Boolean indicating if the registry was deployed by this factory
     */
    function isInstitutionRegistered(address registryAddress) external view returns (bool) {
        return isValidRegistry[registryAddress];
    }

    /**
     * @dev Get the total number of registered institutions
     * @return The count of registered institutions
     */
    function getInstitutionCount() external view returns (uint256) {
        return deployedRegistries.length;
    }

    /**
     * @dev Get registry address by index
     * @param index The index in the deployedRegistries array
     * @return The registry address
     */
    function getInstitutionByIndex(uint256 index) external view returns (address) {
        require(index < deployedRegistries.length, "Index out of bounds");
        return deployedRegistries[index];
    }

    /**
     * @dev Get all deployed registry addresses
     * @return Array of all registry addresses
     */
    function getAllInstitutions() external view returns (address[] memory) {
        return deployedRegistries;
    }

    /**
     * @dev Get institution details including name, admin, and URL
     * @param registryAddress The registry contract address
     * @return admin The admin address of the registry
     * @return institutionName The name of the institution
     * @return url The URL of the institution
     * @return isRegistered Whether the registry is registered with this factory
     */
    function getInstitutionDetails(address registryAddress)
        external
        view
        returns (address admin, string memory institutionName, string memory url, bool isRegistered)
    {
        isRegistered = isValidRegistry[registryAddress];
        if (isRegistered) {
            VeridocsRegistry registry = VeridocsRegistry(registryAddress);
            admin = registry.admin();
            institutionName = registry.institutionName();
            url = registry.institutionUrl();
        }
    }

    /**
     * @dev Get comprehensive factory statistics
     * @return totalInstitutions Total number of registered institutions
     * @return factoryOwner The owner of this factory
     */
    function getFactoryStats() external view returns (uint256 totalInstitutions, address factoryOwner) {
        return (deployedRegistries.length, owner());
    }
}
