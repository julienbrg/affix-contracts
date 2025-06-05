// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.28;

import { VeridocsRegistry } from "./VeridocsRegistry.sol";

/**
 * @title VeridocsFactory
 * @dev Factory contract for creating and managing VeridocsRegistry contracts for institutions
 * @author Genji Team
 */
contract VeridocsFactory {
    // Mapping from admin address to their registry contract address
    mapping(address => address) public institutionContracts;

    // Mapping to check if an admin is authorized
    mapping(address => bool) public authorizedAdmins;

    // Array of all registered admins for enumeration
    address[] public allAdmins;

    // Events
    event InstitutionRegistered(address indexed admin, address indexed contractAddress, string institutionName);

    event InstitutionUpdated(address indexed admin, string newName);

    /**
     * @dev Register a new institution and deploy their VeridocsRegistry contract
     * @param name The name of the institution
     */
    function registerInstitution(string memory name) external {
        require(bytes(name).length > 0, "Institution name cannot be empty");
        require(!authorizedAdmins[msg.sender], "Admin already registered");

        // Deploy new VeridocsRegistry contract
        VeridocsRegistry newRegistry = new VeridocsRegistry(msg.sender, name);
        address registryAddress = address(newRegistry);

        // Update mappings
        institutionContracts[msg.sender] = registryAddress;
        authorizedAdmins[msg.sender] = true;
        allAdmins.push(msg.sender);

        emit InstitutionRegistered(msg.sender, registryAddress, name);
    }

    /**
     * @dev Update institution name (only the admin itself can call this)
     * @param newName The new name for the institution
     * @notice This function is deprecated. Use the registry's updateInstitutionName function directly.
     */
    function updateInstitutionName(string memory newName) external view {
        require(authorizedAdmins[msg.sender], "Admin not registered");
        require(bytes(newName).length > 0, "Institution name cannot be empty");

        // Note: This function cannot work as designed because the registry expects
        // msg.sender to be the admin, not this factory contract.
        // Users should call updateInstitutionName directly on their registry contract.
        revert("Use registry.updateInstitutionName() directly");
    }

    /**
     * @dev Get the registry contract address for an admin
     * @param admin The admin address
     * @return The registry contract address
     */
    function getInstitutionRegistry(address admin) external view returns (address) {
        require(authorizedAdmins[admin], "Admin not registered");
        return institutionContracts[admin];
    }

    /**
     * @dev Check if an admin is registered
     * @param admin The admin address to check
     * @return Boolean indicating if the admin is registered
     */
    function isInstitutionRegistered(address admin) external view returns (bool) {
        return authorizedAdmins[admin];
    }

    /**
     * @dev Get the total number of registered institutions
     * @return The count of registered institutions
     */
    function getInstitutionCount() external view returns (uint256) {
        return allAdmins.length;
    }

    /**
     * @dev Get admin address by index
     * @param index The index in the allAdmins array
     * @return The admin address
     */
    function getInstitutionByIndex(uint256 index) external view returns (address) {
        require(index < allAdmins.length, "Index out of bounds");
        return allAdmins[index];
    }

    /**
     * @dev Get all registered admins
     * @return Array of all admin addresses
     */
    function getAllInstitutions() external view returns (address[] memory) {
        return allAdmins;
    }

    /**
     * @dev Get institution details including name and registry address
     * @param admin The admin address
     * @return registryAddress The registry contract address
     * @return institutionName The name of the institution
     * @return isRegistered Whether the admin is registered
     */
    function getInstitutionDetails(address admin)
        external
        view
        returns (address registryAddress, string memory institutionName, bool isRegistered)
    {
        isRegistered = authorizedAdmins[admin];
        if (isRegistered) {
            registryAddress = institutionContracts[admin];
            VeridocsRegistry registry = VeridocsRegistry(registryAddress);
            institutionName = registry.institutionName();
        }
    }
}
