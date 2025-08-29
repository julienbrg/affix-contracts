// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AffixRegistry } from "./AffixRegistry.sol";

/**
 * @title AffixFactory
 * @dev Factory contract for creating and managing AffixRegistry contracts for entitys
 * @notice Only the owner can register new entitys
 */
contract AffixFactory is Ownable {
    // Array of all deployed registry addresses for enumeration
    address[] public deployedRegistries;

    // Mapping to check if a registry address is valid (deployed by this factory)
    mapping(address => bool) public isValidRegistry;

    // Events
    event EntityRegistered(address indexed admin, address indexed contractAddress, string entityName, string url);

    /**
     * @dev Constructor - sets the specified address as the owner
     * @param initialOwner The address that will become the owner of this factory
     */
    constructor(address initialOwner) Ownable(initialOwner) {
        require(initialOwner != address(0), "Initial owner cannot be zero address");
    }

    /**
     * @dev Register a new entity and deploy their AffixRegistry contract
     * @param admin The address that will be the admin of the new registry
     * @param name The name of the entity
     * @param url The URL associated with the entity (e.g., website, verification portal)
     * @notice Only the factory owner can register new entitys
     * @return registryAddress The address of the newly deployed registry
     */
    function registerEntity(
        address admin,
        string memory name,
        string memory url
    ) external onlyOwner returns (address registryAddress) {
        require(admin != address(0), "Invalid admin address");
        require(bytes(name).length > 0, "Entity name cannot be empty");
        require(bytes(url).length > 0, "Entity URL cannot be empty");

        // Deploy new AffixRegistry contract
        AffixRegistry newRegistry = new AffixRegistry(admin, name, url);
        registryAddress = address(newRegistry);

        // Update tracking
        deployedRegistries.push(registryAddress);
        isValidRegistry[registryAddress] = true;

        emit EntityRegistered(admin, registryAddress, name, url);
    }

    /**
     * @dev Check if an entity registry is deployed by this factory
     * @param registryAddress The registry address to check
     * @return Boolean indicating if the registry was deployed by this factory
     */
    function isEntityRegistered(address registryAddress) external view returns (bool) {
        return isValidRegistry[registryAddress];
    }

    /**
     * @dev Get the total number of registered entitys
     * @return The count of registered entitys
     */
    function getEntityCount() external view returns (uint256) {
        return deployedRegistries.length;
    }

    /**
     * @dev Get registry address by index
     * @param index The index in the deployedRegistries array
     * @return The registry address
     */
    function getEntityByIndex(uint256 index) external view returns (address) {
        require(index < deployedRegistries.length, "Index out of bounds");
        return deployedRegistries[index];
    }

    /**
     * @dev Get all deployed registry addresses
     * @return Array of all registry addresses
     */
    function getAllEntitys() external view returns (address[] memory) {
        return deployedRegistries;
    }

    /**
     * @dev Get entity details including name, admin, and URL
     * @param registryAddress The registry contract address
     * @return admin The admin address of the registry
     * @return entityName The name of the entity
     * @return url The URL of the entity
     * @return isRegistered Whether the registry is registered with this factory
     */
    function getEntityDetails(
        address registryAddress
    ) external view returns (address admin, string memory entityName, string memory url, bool isRegistered) {
        isRegistered = isValidRegistry[registryAddress];
        if (isRegistered) {
            AffixRegistry registry = AffixRegistry(registryAddress);
            admin = registry.admin();
            entityName = registry.entityName();
            url = registry.entityUrl();
        }
    }

    /**
     * @dev Get comprehensive factory statistics
     * @return totalEntitys Total number of registered entitys
     * @return factoryOwner The owner of this factory
     */
    function getFactoryStats() external view returns (uint256 totalEntitys, address factoryOwner) {
        return (deployedRegistries.length, owner());
    }
}
